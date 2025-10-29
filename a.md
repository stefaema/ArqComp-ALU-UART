stateDiagram-v2
    [*] --> S_IDLE

    S_IDLE --> S_START_BIT: falling_edge

    S_START_BIT --> S_IDLE: tick_16x & serial_in==1
    S_START_BIT --> S_DATA_BITS: tick_16x & tick_count==7

    S_DATA_BITS --> S_STOP_BIT: bit_index==7
    S_DATA_BITS --> S_DATA_BITS: bit_index!=7

    S_STOP_BIT --> S_DONE: tick_count==15

    S_DONE --> S_IDLE
