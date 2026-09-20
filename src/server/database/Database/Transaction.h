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

#ifndef _TRANSACTION_H
#define _TRANSACTION_H

#include "DatabaseEnvFwd.h"
#include "Define.h"
#include "SQLOperation.h"
#include "StringFormat.h"
#include <functional>
#include <algorithm>
#include <atomic>
#include <future>
#include <mutex>
#include <vector>

// A COMMIT/ROLLBACK acknowledgement was not confirmed. Reconcile a durable
// operation ID before retrying or restoring item/money state. Not a rollback result.
constexpr int TRANSACTION_RESULT_UNKNOWN = -2;

// Completion is shared without a Player/Item pointer crossing database threads.
constexpr int TRANSACTION_PENDING = 2147483647;
constexpr int TRANSACTION_PRECONDITION_FAILED = -3;
class TransactionWriteWatch
{
public:
    void Observe(std::shared_ptr<std::atomic<int>> const& token)
    {
        Status();
        if (std::find(tokens.begin(), tokens.end(), token) == tokens.end()) tokens.push_back(token);
    }
    int Status()
    {
        int result = 0;
        for (auto it = tokens.begin(); it != tokens.end();)
        {
            int code = (*it)->load();
            if (code == 0) { it = tokens.erase(it); continue; }
            if (code == TRANSACTION_PENDING) { if (!result) result = 1; }
            else { failed = true; it = tokens.erase(it); continue; }
            ++it;
        }
        return failed ? -1 : result; // Latch failures, but do not retain every failed token.
    }
private:
    std::vector<std::shared_ptr<std::atomic<int>>> tokens;
    bool failed = false;
};

/*! Transactions, high level class. */
class AC_DATABASE_API TransactionBase
{
    friend class TransactionTask;
    friend class MySQLConnection;

    template <typename T>
    friend class DatabaseWorkerPool;

public:
    TransactionBase()  = default;
    virtual ~TransactionBase() { Cleanup(); }

    void Append(std::string_view sql);
    void ExpectAffectedRows(uint64 count)
    {
        SQLElementData data{}; data.type = SQL_ELEMENT_EXPECT_AFFECTED;
        data.element = count; m_queries.emplace_back(data);
    }
    std::shared_ptr<std::atomic<int>> CompletionToken() const { return completion; }
    void Complete(int result)
    {
        int expected = TRANSACTION_PENDING;
        completion->compare_exchange_strong(expected, result);
    }

    template<typename... Args>
    void Append(std::string_view sql, Args&&... args)
    {
        Append(Acore::StringFormat(sql, std::forward<Args>(args)...));
    }

    [[nodiscard]] std::size_t GetSize() const { return m_queries.size(); }

protected:
    void AppendPreparedStatement(PreparedStatementBase* statement);
    void Cleanup();
    std::vector<SQLElementData> m_queries;

private:
    bool _cleanedUp{false};
    std::shared_ptr<std::atomic<int>> completion = std::make_shared<std::atomic<int>>(TRANSACTION_PENDING);
};

template<typename T>
class Transaction : public TransactionBase
{
public:
    using TransactionBase::Append;

    void Append(PreparedStatement<T>* statement)
    {
        AppendPreparedStatement(statement);
    }
};

/*! Low level class*/
class AC_DATABASE_API TransactionTask : public SQLOperation
{
    template <class T>
    friend class DatabaseWorkerPool;

    friend class DatabaseWorker;
    friend class TransactionCallback;

public:
    TransactionTask(std::shared_ptr<TransactionBase> trans) : m_trans(std::move(trans)) { }
    ~TransactionTask() override = default;

protected:
    bool Execute() override;
    int TryExecute();
    int ExecuteWithRetries();
    void CleanupOnFailure();

    std::shared_ptr<TransactionBase> m_trans;
    static std::mutex _deadlockLock;
};

class AC_DATABASE_API TransactionWithResultTask : public TransactionTask
{
public:
    TransactionWithResultTask(std::shared_ptr<TransactionBase> trans) : TransactionTask(trans) { }

    TransactionFuture GetFuture() { return m_result.get_future(); }

protected:
    bool Execute() override;

    TransactionPromise m_result;
};

// Opt-in status API for operations such as original-item vault transfers.
// 0: acknowledged commit; -2: outcome unknown; other: transaction not committed
// (requires transactional DML only; no DDL or nontransactional tables).
class AC_DATABASE_API TransactionWithStatusTask : public TransactionTask
{
public:
    explicit TransactionWithStatusTask(std::shared_ptr<TransactionBase> trans) : TransactionTask(std::move(trans)) { }
    std::future<int> GetFuture() { return m_status.get_future(); }

protected:
    bool Execute() override;

private:
    std::promise<int> m_status;
};

class AC_DATABASE_API TransactionCallback
{
public:
    TransactionCallback(TransactionFuture&& future) : m_future(std::move(future)) { }
    TransactionCallback(TransactionCallback&&) = default;

    TransactionCallback& operator=(TransactionCallback&&) = default;

    void AfterComplete(std::function<void(bool)> callback) &
    {
        m_callback = std::move(callback);
    }

    bool InvokeIfReady();

    TransactionFuture m_future;
    std::function<void(bool)> m_callback;
};

#endif
