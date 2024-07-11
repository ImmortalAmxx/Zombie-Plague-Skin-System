/**
    History of changes:
        - 1.1 beta (20.05.2022) - First release.
        - 1.2 (17.12.2022) - Edit bug with checks (Thanks cookie.).
        - 1.3 (11.03.2023) - Code changes, added ability to set validity time.
        - 1.4 (11.07.2024) - Another code refactoring. Replaced RequestFrame with set_task (because of zombie mod).

    Acknowledgements: b0t.
*/

#include <amxmodx>
#include <reapi>
#include <zombieplague>

const TASKID__SETMODEL = 73241;

native zp_override_user_model(iIndex, szModelName[], iMIndex);

enum any: eArrayData {
    ARRAY__KEY[4],
    ARRAY__VALUE[32],
    ARRAY__MODEL_NAME[32],
    ARRAY__BODY,
    ARRAY__SKIN,
    ARRAY__TIME[32],
    ARRAY__MODEL_INDEX
};

new const FILE__PATH[] = "addons/amxmodx/configs/re_zpmodels.ini";

new 
    gl__pArrayIndex[MAX_PLAYERS + 1],
    Array: gl__aModelData;

public plugin_precache() {
    gl__aModelData = ArrayCreate(eArrayData);
    @Read__File();
}

public plugin_init() {
    register_plugin("[ZP 4.3] System: Models", "1.4", "ImmortalAmxx");
    RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer__Spawn_Post", true);
}

public client_putinserver(UserId) {
    for(new iCase, ArrayData[eArrayData]; iCase < ArraySize(gl__aModelData); iCase++) {
        ArrayGetArray(gl__aModelData, iCase, ArrayData);

        static szKey[64];
        switch(ArrayData[ARRAY__KEY]) {
            case 's': {
                get_user_authid(UserId, szKey, charsmax(szKey));

                if(equal(szKey, ArrayData[ARRAY__VALUE])) {
                    gl__pArrayIndex[UserId] = iCase;
                    break;
                }                
            }
            case 'f': {
                if(get_user_flags(UserId) & read_flags(ArrayData[ARRAY__VALUE])) {
                    gl__pArrayIndex[UserId] = iCase;
                    break;
                }
            }
            case 'i': {
                get_user_ip(UserId, szKey, charsmax(szKey), 1);

                if(equal(szKey, ArrayData[ARRAY__VALUE])) {
                    gl__pArrayIndex[UserId] = iCase;
                    break;              
                }
            }
            case 'n': {
                get_user_name(UserId, szKey, charsmax(szKey));

                if(equal(szKey, ArrayData[ARRAY__VALUE])) {
                    gl__pArrayIndex[UserId] = iCase;
                    break;              
                }
            }
        }
    }
}

@CBasePlayer__Spawn_Post(UserId) {
    remove_task(UserId + TASKID__SETMODEL);
    set_task(0.5, "@SetUserModel", UserId + TASKID__SETMODEL);       
}

public zp_user_humanized_post(UserId, pSurvivor) {
    if(pSurvivor)
        return;
    
    remove_task(UserId + TASKID__SETMODEL);
    set_task(0.5, "@SetUserModel", UserId + TASKID__SETMODEL);
}

@SetUserModel(UserId) {
    UserId -= TASKID__SETMODEL;

    if(is_user_alive(UserId) && gl__pArrayIndex[UserId] != -1) {
        if(!zp_get_user_survivor(UserId) && !zp_get_user_nemesis(UserId) && !zp_get_user_zombie(UserId)) {
            new ArrayData[eArrayData];
            ArrayGetArray(gl__aModelData, gl__pArrayIndex[UserId], ArrayData);

            new iModelIndex = ArrayData[ARRAY__MODEL_INDEX];

            zp_override_user_model(UserId, ArrayData[ARRAY__MODEL_NAME], iModelIndex);
            set_member(UserId, m_modelIndexPlayer, iModelIndex);

            set_entvar(UserId, var_body, ArrayData[ARRAY__BODY]);
            set_entvar(UserId, var_skin, ArrayData[ARRAY__SKIN]);
        }
    }
}

@Read__File() {
    new iFile = fopen(FILE__PATH, "r");
    
    if(!iFile) {
        set_fail_state("Cant read file ^"%s^"", FILE__PATH);
        return;
    }
    else {
        new szBuffer[256], ArrayData[eArrayData], SysTime, szBody[5], szSkin[5];
        SysTime = get_systime();

        while(fgets(iFile, szBuffer, charsmax(szBuffer))) {
            trim(szBuffer);

            if(szBuffer[0] != '"')
                continue;
            
            parse(szBuffer,
                ArrayData[ARRAY__KEY], charsmax(ArrayData[ARRAY__KEY]),
                ArrayData[ARRAY__VALUE], charsmax(ArrayData[ARRAY__VALUE]),
                ArrayData[ARRAY__MODEL_NAME], charsmax(ArrayData[ARRAY__MODEL_NAME]),
                szBody, charsmax(szBody),
                szSkin, charsmax(szSkin),
                ArrayData[ARRAY__TIME], charsmax(ArrayData[ARRAY__TIME])
            );

            ArrayData[ARRAY__BODY] = str_to_num(szBody);
            ArrayData[ARRAY__SKIN] = str_to_num(szSkin);

            if(file_exists(fmt("models/player/%s/%s.mdl", ArrayData[ARRAY__MODEL_NAME], ArrayData[ARRAY__MODEL_NAME]))) {
                ArrayData[ARRAY__MODEL_INDEX] = precache_model(fmt("models/player/%s/%s.mdl", ArrayData[ARRAY__MODEL_NAME], ArrayData[ARRAY__MODEL_NAME]));
            }
            else {
                server_print("Zombie Plague Skins - Bad load model: %s", ArrayData[ARRAY__MODEL_NAME]);
                server_print("Zombie Plague Skins - Plugin paused.");
                    
                pause("d");
                break;
            }
                
            if(ArrayData[ARRAY__TIME][0] && SysTime >= parse_time(ArrayData[ARRAY__TIME], "%d.%m.%Y %H:%M"))
                continue;

            ArrayPushArray(gl__aModelData, ArrayData);
        }

        fclose(iFile);
    }
}
