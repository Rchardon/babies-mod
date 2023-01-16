import {
  DamageFlag,
  DamageFlagZero,
  EffectVariant,
  EntityType,
  ModCallback,
} from "isaac-typescript-definitions";
import {
  Callback,
  CallbackCustom,
  ModCallbackCustom,
  spawnEffect,
  VectorZero,
} from "isaacscript-common";
import { Baby } from "../Baby";

/** Spawns creep on hit (improved). */
export class DBaby extends Baby {
  // 11
  @Callback(ModCallback.ENTITY_TAKE_DMG)
  entityTakeDmg(
    entity: Entity,
    _amount: float,
    _damageFlags: BitFlags<DamageFlag>,
    source: EntityRef,
    countdownFrames: int,
  ): boolean | undefined {
    if (
      source.Type === EntityType.EFFECT &&
      source.Variant === (EffectVariant.PLAYER_CREEP_RED as int)
    ) {
      // By default, player creep only deals 2 damage per tick, so increase the damage.
      const player = Isaac.GetPlayer();
      const damage = player.Damage * 2;
      entity.TakeDamage(
        damage,
        DamageFlagZero,
        EntityRef(player),
        countdownFrames,
      );
      return false;
    }

    return undefined;
  }

  // 11
  @CallbackCustom(ModCallbackCustom.ENTITY_TAKE_DMG_PLAYER)
  entityTakeDmgPlayer(player: EntityPlayer): boolean | undefined {
    const creep = spawnEffect(
      EffectVariant.PLAYER_CREEP_RED,
      0,
      player.Position,
      VectorZero,
      player,
    );
    creep.Scale = 10;
    creep.Timeout = 240;

    return undefined;
  }
}
