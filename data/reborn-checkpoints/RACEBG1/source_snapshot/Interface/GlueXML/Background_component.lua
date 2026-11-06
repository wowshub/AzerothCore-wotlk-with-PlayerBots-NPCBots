function SetBackgroundModel(model, name, raza, zoom, gender)
 -- RACEUI1A: scene alias only. SelectCharacter still loads the real race model.
 if model==CharacterSelect and type(name)=="string" then
  local token=string.upper(name)
  if token=="REBORNSETHRAK" then name="Human"
  elseif token=="REBORNOGRE" then name="Orc" end
 end


    local nameupper = strupper(name);
    local ligthning = "BLOODELF"
    if(name == "NightElf" or name == "Scourge")then
        ligthning = "NIGHTELF"
    end
    local path = "Interface\\Glues\\Models\\UI_"..name.."\\UI_"..name..".m2";
    if ( model == CharacterCreate ) then
        if(raza == 900 or raza == 2000 )then
            if(GetSelectedSex() == SEX_MALE)then
                SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\custom\\UI_AllianceDoopel.m2")
            else
                if (nameupper == "HUMAN") then
                    SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                else
                    SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_HORDE\\UI_HORDE.m2")
                end
            end
        else
            if (nameupper == "ORC") then
                if(zoom == 1)then
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1")
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2p")

                    if(raza == 20)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2");
                    elseif(raza == 12)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\orc\\normal\\z_orc_n.m2");
                    elseif(raza == 13)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\scourge\\normal\\z_scourge_n.m2");
                    elseif(raza == 14)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\tauren\\normal\\z_tauren_n.m2");
                    elseif(raza == 15)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\troll\\normal\\z_troll_n.m2");
                    elseif(raza == 16)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\goblin\\normal\\z_goblin_n.m2");
                    elseif(raza == 17)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\bloodelf\\normal\\z_bloodelf_n.m2");
                    elseif(raza == 21)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2");
                    elseif(raza == 18)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\vulpera\\normal\\z_vulpera_n.m2");
                    elseif(raza == 19)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_PandarenC.m2");
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_HORDE\\UI_HORDE.m2")
                    end

                else
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2")
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1p")

                    if(CharacterCreateFrame.state == "CUSTOMIZATION")then
                        if(raza == 12)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\orc\\zoom\\z_orc_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\orc\\zoom\\z_orc_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale1.m2");
                            end
                        elseif(raza == 14)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\tauren\\zoom\\z_tauren_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\tauren\\zoom\\z_tauren_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale3.m2");
                            end
                        elseif(raza == 13)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\scourge\\zoom\\z_scourge_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale2.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\scourge\\zoom\\z_scourge_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale2.m2");
                            end
                        elseif(raza == 15)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\troll\\zoom\\z_troll_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale4.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\troll\\zoom\\z_troll_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale4.m2");
                            end
                        elseif(raza == 19)then
                            if(GetSelectedSex() == SEX_MALE )then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_Pandaren_zoom1.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale4.m2");
                            else
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_Pandaren_zoom2.m2");
                        --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\custom\\female\\UI_HordeZoomFemale6.m2");
                            end
                        elseif(raza == 16)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\goblin\\zoom\\z_goblin_z.m2");
                        elseif(raza == 21)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale5.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale5.m2");
                            end
                        elseif(raza == 17)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\bloodelf\\zoom\\z_bloodelf_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale5.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\bloodelf\\zoom\\z_bloodelf_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale5.m2");
                            end
                        elseif(raza == 18)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\vulpera\\zoom\\z_vulpera_z.m2")
                        elseif(raza == 20)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale5.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale5.m2");
                            end
                        else
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                        end
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                    end

                end
            elseif (nameupper == "HUMAN") then
                if(zoom == 1)then
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1")
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2p")

                    if(raza == 8)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Worgen\\normal\\z_Worgen_n.m2");
                    elseif(raza == 4)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\gnome\\normal\\z_gnome_n.m2");
                    elseif(raza == 1)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\normal\\z_human_n.m2");
                    elseif(raza == 2)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\enano\\normal\\z_dwarf_n.m2");
                    elseif(raza == 11)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2");
                    elseif(raza == 3)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\nightelf\\normal\\z_nightelf_n.m2");
                    elseif(raza == 5)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\draenei\\normal\\z_draenei_n.m2");
                    elseif(raza == 6)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\normal\\z_Elfo_del_vacio_n.m2");
                    elseif(raza == 7)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\normal\\z_human_n.m2");
                    elseif(raza == 10)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\normal\\z_lightforgeddraenei_n.m2");
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                    end

                else
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2")
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1p")

                    if(CharacterCreateFrame.state == "CUSTOMIZATION")then
                        if(raza == 1)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 2)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\enano\\zoom\\z_dwarf_z.m2");
                        --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale2.m2");
                        end
                        if(raza == 11)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_NightElf_Dh_zoom\\ui_NightElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_NightElf_Dh_zoom\\ui_NightElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale2.m2");
                            end
                        end
                        if(raza == 3)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\nightelf\\zoom\\z_nightelf_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\nightelf\\zoom\\z_nightelf_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale2.m2");
                            end
                        end
                        if(raza == 4)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\gnome\\zoom\\z_gnome_z.m2");
                        --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale4.m2");
                        end
                        if(raza == 5)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\draenei\\zoom\\z_draenei_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\draenei\\zoom\\z_draenei_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale2.m2");
                            end
                        end
                        if(raza == 7)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 10)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\zoom\\z_lightforgeddraenei_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\zoom\\z_lightforgeddraenei_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 6)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\zoom\\z_Elfo_del_vacio_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\zoom\\z_Elfo_del_vacio_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 8)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Worgen\\zoom\\z_Worgen_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\Custom\\male\\UI_AllianceZoomMale6.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Worgen\\zoom\\z_Worgen_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\Custom\\female\\UI_AllianceZoomFemale4.m2");
                            end
                        end
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                    end
                end
            else
                SetCharCustomizeBackground(path);
            end
        end
    else
        GLOBAL_RACE_CHANGE = 0;
        if(name == "Skeleton" or name == "Tuskarr")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2")
        elseif(name == "FelOrc")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Elfo_del_vacio\\UI_Elfo_del_vacio.m2")
        elseif(name == "Broken")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_human\\UI_Human.m2")
        elseif(name == "Naga_")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_vulpera\\ui_vulpera.m2")
        elseif(name == "Gnome")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Gnome\\ui_gnome.m2")
        elseif(name == "Troll")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Troll\\UI_Troll.m2")
        elseif(name == "ForestTroll")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_Pandaren.m2")
        elseif(name == "Taunka")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_lightforgeddraenei\\ui_lightforgeddraenei.m2")
        elseif(name == "NorthrendSkeleton" or name == "IceTroll")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2")
        elseif(name == "Human")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_kultiran\\ui_kultiran.m2")
        elseif(name == "Tauren")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_highmountaintauren\\ui_highmountaintauren.m2")
        elseif(name == "Orc")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Troll\\UI_Troll.m2")

        else
            SetCharSelectBackground(path);
        end
    end
    --PlayGlueAmbience(GlueAmbienceTracks[nameupper], 4.0);
    SetLighting(model, ligthning)
end
