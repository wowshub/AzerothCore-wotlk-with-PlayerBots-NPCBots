/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "Transaction.h"
#include "Errors.h"
#include "Log.h"
#include "MySQLConnection.h"
#include "PreparedStatement.h"
#include "Timer.h"
#include <mysqld_error.h>
#include <sstream>
#include <thread>

std::mutex TransactionTask::_deadlockLock;

constexpr Milliseconds DEADLOCK_MAX_RETRY_TIME_MS = 1min;

//- Append a raw ad-hoc query to the transaction
void TransactionBase::Append(std::string_view sql)
{
    SQLElementData data = {};
    data.type = SQL_ELEMENT_RAW;
    data.element = std::string(sql);
    m_queries.emplace_back(data);
}

//- Append a prepared statement to the transaction
void TransactionBase::AppendPreparedStatement(PreparedStatementBase* stmt)
{
    SQLElementData data = {};
    data.type = SQL_ELEMENT_PREPARED;
    data.element = stmt;
    m_queries.emplace_back(data);
}

void TransactionBase::Cleanup()
{
    Complete(-1); // Dropped/unexecuted transaction. Does not overwrite a terminal result.
    // This might be called by explicit calls to Cleanup or by the auto-destructor
    if (_cleanedUp)
        return;

    for (SQLElementData& data : m_queries)
    {
        switch (data.type)
        {
            case SQL_ELEMENT_PREPARED:
            {
                try
                {
                    PreparedStatementBase* stmt = std::get<PreparedStatementBase*>(data.element);
                    ASSERT(stmt);

                    delete stmt;
                }
                catch (const std::bad_variant_access& ex)
                {
                    LOG_FATAL("sql.sql", "> PreparedStatementBase not found in SQLElementData. {}", ex.what());
                    ABORT();
                }
            }
            break;
            case SQL_ELEMENT_EXPECT_AFFECTED:
                break;
            case SQL_ELEMENT_RAW:
            {
                try
                {
                    std::get<std::string>(data.element).clear();
                }
                catch (const std::bad_variant_access& ex)
                {
                    LOG_FATAL("sql.sql", "> std::string not found in SQLElementData. {}", ex.what());
                    ABORT();
                }
            }
            break;
        }
    }

    m_queries.clear();
    _cleanedUp = true;
}

bool TransactionTask::Execute()
{
    int error = ExecuteWithRetries();
    m_trans->Complete(error);
    if (error)
        CleanupOnFailure();
    return error == 0;
}

int TransactionTask::ExecuteWithRetries()
{
    int error = TryExecute();
    if (error != ER_LOCK_DEADLOCK)
        return error;

    // Retry only a confirmed deadlock rollback. Re-evaluate EVERY attempt:
    // a later disconnect or unknown COMMIT must stop this loop immediately.
    std::lock_guard<std::mutex> lock(_deadlockLock);
    for (Milliseconds elapsed{}, start = GetTimeMS(); elapsed <= DEADLOCK_MAX_RETRY_TIME_MS;
        elapsed = GetMSTimeDiffToNow(start))
    {
        error = TryExecute();
        if (error != ER_LOCK_DEADLOCK)
            return error;
        LOG_WARN("sql.sql", "Deadlocked SQL transaction, retrying. Elapsed: {} ms", elapsed.count());
    }
    LOG_ERROR("sql.sql", "SQL transaction exceeded deadlock retry time.");
    return error;
}

int TransactionTask::TryExecute()
{
    return m_conn->ExecuteTransaction(m_trans);
}

void TransactionTask::CleanupOnFailure()
{
    m_trans->Cleanup();
}

bool TransactionWithResultTask::Execute()
{
    int error = ExecuteWithRetries();
    m_trans->Complete(error);
    if (error)
        CleanupOnFailure();
    m_result.set_value(error == 0);
    return error == 0;
}

bool TransactionWithStatusTask::Execute()
{
    int error = ExecuteWithRetries();
    m_trans->Complete(error);
    if (error)
        CleanupOnFailure();
    m_status.set_value(error);
    return error == 0;
}

bool TransactionCallback::InvokeIfReady()
{
    if (m_future.valid() && m_future.wait_for(0s) == std::future_status::ready)
    {
        m_callback(m_future.get());
        return true;
    }

    return false;
}
