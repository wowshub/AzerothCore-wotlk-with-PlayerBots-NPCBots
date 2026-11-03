# -------------------------------------------------------------------------
# mod-reborn-housing
# 家园系统 H1A：地块、目录、摆放与保存（服务端命令版）
# -------------------------------------------------------------------------

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/mod_reborn_housing_loader.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornHousing.cpp")

AC_ADD_SCRIPT_LOADER("mod_reborn_housing" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod_reborn_housing.conf.dist")
