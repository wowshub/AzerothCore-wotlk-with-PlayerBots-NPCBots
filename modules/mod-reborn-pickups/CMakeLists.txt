# -------------------------------------------------------------------------
# mod-reborn-pickups
# World pickups: once per character, sparkling like a gatherable (WPICK1A)
# -------------------------------------------------------------------------

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/mod_reborn_pickups_loader.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornPickups.cpp")

AC_ADD_SCRIPT_LOADER("mod_reborn_pickups" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod_reborn_pickups.conf.dist")
