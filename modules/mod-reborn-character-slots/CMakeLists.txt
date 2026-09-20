# RebornWOW account-level paid character slots
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornCharacterSlots.cpp")
AC_ADD_SCRIPT_LOADER("RebornCharacterSlots" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/RebornCharacterSlots.conf.dist")
