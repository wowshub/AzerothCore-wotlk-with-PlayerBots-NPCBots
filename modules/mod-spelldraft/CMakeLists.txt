# [beascend] mod-spelldraft module build wiring
# Upstream ships no CMakeLists (it deploys C++ via install.sh core injection).
# For a proper module build we compile its script + loader here.
AC_ADD_SCRIPT("${CMAKE_CURRENT_SOURCE_DIR}/src/SpellDraft.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_SOURCE_DIR}/src/SpellDraftDkScaling.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_SOURCE_DIR}/src/SpellDraftNativeAuraDiag.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_SOURCE_DIR}/src/SpellDraftGlyphCollection.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_SOURCE_DIR}/src/SpellDraftMonk.cpp")
AC_ADD_SCRIPT("${CMAKE_CURRENT_SOURCE_DIR}/src/mod_spelldraft_loader.cpp")

AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_SOURCE_DIR}/conf/mod_spelldraft.conf.dist")
