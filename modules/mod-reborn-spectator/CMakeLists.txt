# RebornWOW spectator prototype module

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornSpectator.cpp")

AC_ADD_SCRIPT_LOADER("RebornSpectator" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")

AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/RebornSpectator.conf.dist")
