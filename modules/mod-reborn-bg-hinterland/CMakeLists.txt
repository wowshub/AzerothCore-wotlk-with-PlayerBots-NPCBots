# -------------------------------------------------------------------------
# mod-reborn-bg-hinterland
# Hinterland battleground (HLBG1A): port of DarkChaos-255 HinterlandBG, type 20 / queue 14 / map 20411
# -------------------------------------------------------------------------

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/mod_reborn_bg_hinterland_loader.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornBGHinterland.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/BattlegroundHLBG.cpp")

AC_ADD_SCRIPT_LOADER("mod_reborn_bg_hinterland" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod_reborn_bg_hinterland.conf.dist")
