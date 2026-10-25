# -------------------------------------------------------------------------
# mod-reborn-treasure
# 野外寻宝宝箱系统 (阶段 TREAS1A)
# -------------------------------------------------------------------------

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/mod_reborn_treasure_loader.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornTreasure.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornTreasureCommands.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornTreasureClue.cpp")

AC_ADD_SCRIPT_LOADER("mod_reborn_treasure" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod_reborn_treasure.conf.dist")
