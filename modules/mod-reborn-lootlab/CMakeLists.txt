# -------------------------------------------------------------------------
# mod-reborn-lootlab
# 掉落工坊 LootLab: browse, simulate and (later) edit every loot table (stage LAB1)
# -------------------------------------------------------------------------

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/mod_reborn_lootlab_loader.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/LootLab.cpp")

AC_ADD_SCRIPT_LOADER("mod_reborn_lootlab" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod_reborn_lootlab.conf.dist")
