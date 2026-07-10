import QtQuick

// Animation component with Caelestia-compatible type enum.
// Legacy names (Enter, Exit, Fast, Normal, Slow) are aliased to closest equivalents.
NumberAnimation {
    enum Type {
        StandardSmall        = 0,
        Standard             = 1,
        StandardLarge        = 2,
        StandardExtraLarge   = 3,
        EmphasizedSmall      = 4,
        Emphasized           = 5,
        EmphasizedLarge      = 6,
        EmphasizedExtraLarge = 7,
        FastSpatial          = 8,
        DefaultSpatial       = 9,
        SlowSpatial          = 10,
        FastEffects          = 11,
        DefaultEffects       = 12,
        SlowEffects          = 13,
        // Legacy aliases — map to nearest Caelestia equivalent
        Fast                 = 11,
        Normal               = 9,
        Slow                 = 10,
        Enter                = 8,
        Exit                 = 11
    }

    property int type: Anim.DefaultSpatial

    duration: {
        switch (type) {
            case Anim.StandardSmall:        return 100
            case Anim.Standard:             return 200
            case Anim.StandardLarge:        return 300
            case Anim.StandardExtraLarge:   return 400
            case Anim.EmphasizedSmall:      return 200
            case Anim.Emphasized:           return 300
            case Anim.EmphasizedLarge:      return 400
            case Anim.EmphasizedExtraLarge: return 500
            case Anim.FastSpatial:          return 200
            case Anim.DefaultSpatial:       return 300
            case Anim.SlowSpatial:          return 500
            case Anim.FastEffects:          return 100
            case Anim.DefaultEffects:       return 200
            case Anim.SlowEffects:          return 300
            default:                        return 250
        }
    }

    easing.type: {
        switch (type) {
            case Anim.FastSpatial:
            case Anim.DefaultSpatial:
            case Anim.SlowSpatial:
            case Anim.Enter:            return Easing.OutCubic
            case Anim.FastEffects:
            case Anim.DefaultEffects:
            case Anim.SlowEffects:      return Easing.InOutCubic
            case Anim.EmphasizedSmall:
            case Anim.Emphasized:
            case Anim.EmphasizedLarge:
            case Anim.EmphasizedExtraLarge: return Easing.OutBack
            default:                    return Easing.InOutCubic
        }
    }
}
