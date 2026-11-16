local Config = {
    Range = 8,
    BlockDuration = 0.8,

    TrackingRange = 25,
    ScanInterval = 0.2,
    TintedVisionRange = 75,
    TintedVisionScanInterval = 0.35,

    Features = {
        AutoBlock = false,
        FastInteract = false,
        ShowHiddenKills = false,
        TintedVision = false,
        ProximityTracking = false,
        DashDetection = false
    },

    Debug = true,
    M1OutcomeDebug = true
}

return Config
