// Generated by svd2swift.

import MMIO

/// Pulse Count Controller
@RegisterBlock
public struct PCNT {
    /// Counter value for unit %s
    @RegisterBlock(offset: 0x30, stride: 0x4, count: 4)
    public var u_cnt: RegisterArray<U_CNT>

    /// Interrupt raw status register
    @RegisterBlock(offset: 0x40)
    public var int_raw: Register<INT_RAW>

    /// Interrupt status register
    @RegisterBlock(offset: 0x44)
    public var int_st: Register<INT_ST>

    /// Interrupt enable register
    @RegisterBlock(offset: 0x48)
    public var int_ena: Register<INT_ENA>

    /// Interrupt clear register
    @RegisterBlock(offset: 0x4c)
    public var int_clr: Register<INT_CLR>

    /// PNCT UNIT%s status register
    @RegisterBlock(offset: 0x50, stride: 0x4, count: 4)
    public var u_status: RegisterArray<U_STATUS>

    /// Control register for all counters
    @RegisterBlock(offset: 0x60)
    public var ctrl: Register<CTRL>

    /// PCNT version control register
    @RegisterBlock(offset: 0xfc)
    public var date: Register<DATE>

    /// Cluster UNIT%s, containing U?_CONF0, U?_CONF1, U?_CONF2
    @RegisterBlock(offset: 0x0, stride: 0xc, count: 4)
    public var unit: RegisterArray<UNIT>
}

extension PCNT {
    /// Counter value for unit %s
    @Register(bitWidth: 32)
    public struct U_CNT {
        /// This register stores the current pulse count value for unit %s.
        @ReadOnly(bits: 0..<16)
        public var cnt: CNT
    }

    /// Interrupt raw status register
    @Register(bitWidth: 32)
    public struct INT_RAW {
        /// The raw interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 0..<1)
        public var cnt_thr_event_u0: CNT_THR_EVENT_U0

        /// The raw interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 1..<2)
        public var cnt_thr_event_u1: CNT_THR_EVENT_U1

        /// The raw interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 2..<3)
        public var cnt_thr_event_u2: CNT_THR_EVENT_U2

        /// The raw interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 3..<4)
        public var cnt_thr_event_u3: CNT_THR_EVENT_U3
    }

    /// Interrupt status register
    @Register(bitWidth: 32)
    public struct INT_ST {
        /// The masked interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 0..<1)
        public var cnt_thr_event_u0: CNT_THR_EVENT_U0

        /// The masked interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 1..<2)
        public var cnt_thr_event_u1: CNT_THR_EVENT_U1

        /// The masked interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 2..<3)
        public var cnt_thr_event_u2: CNT_THR_EVENT_U2

        /// The masked interrupt status bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadOnly(bits: 3..<4)
        public var cnt_thr_event_u3: CNT_THR_EVENT_U3
    }

    /// Interrupt enable register
    @Register(bitWidth: 32)
    public struct INT_ENA {
        /// The interrupt enable bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadWrite(bits: 0..<1)
        public var cnt_thr_event_u0: CNT_THR_EVENT_U0

        /// The interrupt enable bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadWrite(bits: 1..<2)
        public var cnt_thr_event_u1: CNT_THR_EVENT_U1

        /// The interrupt enable bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadWrite(bits: 2..<3)
        public var cnt_thr_event_u2: CNT_THR_EVENT_U2

        /// The interrupt enable bit for the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @ReadWrite(bits: 3..<4)
        public var cnt_thr_event_u3: CNT_THR_EVENT_U3
    }

    /// Interrupt clear register
    @Register(bitWidth: 32)
    public struct INT_CLR {
        /// Set this bit to clear the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @WriteOnly(bits: 0..<1)
        public var cnt_thr_event_u0: CNT_THR_EVENT_U0

        /// Set this bit to clear the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @WriteOnly(bits: 1..<2)
        public var cnt_thr_event_u1: CNT_THR_EVENT_U1

        /// Set this bit to clear the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @WriteOnly(bits: 2..<3)
        public var cnt_thr_event_u2: CNT_THR_EVENT_U2

        /// Set this bit to clear the PCNT_CNT_THR_EVENT_U%s_INT interrupt.
        @WriteOnly(bits: 3..<4)
        public var cnt_thr_event_u3: CNT_THR_EVENT_U3
    }

    /// PNCT UNIT%s status register
    @Register(bitWidth: 32)
    public struct U_STATUS {
        /// The pulse counter status of PCNT_U%s corresponding to 0. 0: pulse counter decreases from positive to 0. 1: pulse counter increases from negative to 0. 2: pulse counter is negative. 3: pulse counter is positive.
        @ReadOnly(bits: 0..<2)
        public var zero_mode: ZERO_MODE

        /// The latched value of thres1 event of PCNT_U%s when threshold event interrupt is valid. 1: the current pulse counter equals to thres1 and thres1 event is valid. 0: others
        @ReadOnly(bits: 2..<3)
        public var thres1: THRES1

        /// The latched value of thres0 event of PCNT_U%s when threshold event interrupt is valid. 1: the current pulse counter equals to thres0 and thres0 event is valid. 0: others
        @ReadOnly(bits: 3..<4)
        public var thres0: THRES0

        /// The latched value of low limit event of PCNT_U%s when threshold event interrupt is valid. 1: the current pulse counter equals to thr_l_lim and low limit event is valid. 0: others
        @ReadOnly(bits: 4..<5)
        public var l_lim: L_LIM

        /// The latched value of high limit event of PCNT_U%s when threshold event interrupt is valid. 1: the current pulse counter equals to thr_h_lim and high limit event is valid. 0: others
        @ReadOnly(bits: 5..<6)
        public var h_lim: H_LIM

        /// The latched value of zero threshold event of PCNT_U%s when threshold event interrupt is valid. 1: the current pulse counter equals to 0 and zero threshold event is valid. 0: others
        @ReadOnly(bits: 6..<7)
        public var zero: ZERO
    }

    /// Control register for all counters
    @Register(bitWidth: 32)
    public struct CTRL {
        /// Set this bit to clear unit%s's counter.
        @ReadWrite(bits: 0..<1)
        public var cnt_rst_u0: CNT_RST_U0

        /// Set this bit to clear unit%s's counter.
        @ReadWrite(bits: 2..<3)
        public var cnt_rst_u1: CNT_RST_U1

        /// Set this bit to clear unit%s's counter.
        @ReadWrite(bits: 4..<5)
        public var cnt_rst_u2: CNT_RST_U2

        /// Set this bit to clear unit%s's counter.
        @ReadWrite(bits: 6..<7)
        public var cnt_rst_u3: CNT_RST_U3

        /// Set this bit to pause unit%s's counter.
        @ReadWrite(bits: 1..<2)
        public var cnt_pause_u0: CNT_PAUSE_U0

        /// Set this bit to pause unit%s's counter.
        @ReadWrite(bits: 3..<4)
        public var cnt_pause_u1: CNT_PAUSE_U1

        /// Set this bit to pause unit%s's counter.
        @ReadWrite(bits: 5..<6)
        public var cnt_pause_u2: CNT_PAUSE_U2

        /// Set this bit to pause unit%s's counter.
        @ReadWrite(bits: 7..<8)
        public var cnt_pause_u3: CNT_PAUSE_U3

        /// The registers clock gate enable signal of PCNT module. 1: the registers can be read and written by application. 0: the registers can not be read or written by application
        @ReadWrite(bits: 16..<17)
        public var clk_en: CLK_EN
    }

    /// PCNT version control register
    @Register(bitWidth: 32)
    public struct DATE {
        /// This is the PCNT version control register.
        @ReadWrite(bits: 0..<32)
        public var date_field: DATE_FIELD
    }

    /// Cluster UNIT%s, containing U?_CONF0, U?_CONF1, U?_CONF2
    @RegisterBlock
    public struct UNIT {
        /// Configuration register 0 for unit
        @RegisterBlock(offset: 0x0)
        public var conf0: Register<CONF0>

        /// Configuration register 1 for unit 0
        @RegisterBlock(offset: 0x4)
        public var conf1: Register<CONF1>

        /// Configuration register 2 for unit 0
        @RegisterBlock(offset: 0x8)
        public var conf2: Register<CONF2>
    }
}

extension PCNT.UNIT {
    /// Configuration register 0 for unit
    @Register(bitWidth: 32)
    public struct CONF0 {
        /// Any pulses with width less than this will be ignored when the filter is enabled.
        @ReadWrite(bits: 0..<10)
        public var filter_thres: FILTER_THRES

        /// This is the enable bit for unit %s's input filter.
        @ReadWrite(bits: 10..<11)
        public var filter_en: FILTER_EN

        /// This is the enable bit for unit %s's zero comparator.
        @ReadWrite(bits: 11..<12)
        public var thr_zero_en: THR_ZERO_EN

        /// This is the enable bit for unit %s's thr_h_lim comparator.
        @ReadWrite(bits: 12..<13)
        public var thr_h_lim_en: THR_H_LIM_EN

        /// This is the enable bit for unit %s's thr_l_lim comparator.
        @ReadWrite(bits: 13..<14)
        public var thr_l_lim_en: THR_L_LIM_EN

        /// This is the enable bit for unit %s's thres0 comparator.
        @ReadWrite(bits: 14..<15)
        public var thr_thres0_en: THR_THRES0_EN

        /// This is the enable bit for unit %s's thres1 comparator.
        @ReadWrite(bits: 15..<16)
        public var thr_thres1_en: THR_THRES1_EN

        /// Configures the behavior when the signal input of channel %s detects a negative edge.
        @ReadWrite(bits: 16..<18, as: EdgeMode.self)
        public var ch_neg_mode0: CH_NEG_MODE0

        /// Configures the behavior when the signal input of channel %s detects a negative edge.
        @ReadWrite(bits: 24..<26, as: EdgeMode.self)
        public var ch_neg_mode1: CH_NEG_MODE1

        /// Configures the behavior when the signal input of channel %s detects a positive edge.
        @ReadWrite(bits: 18..<20, as: EdgeMode.self)
        public var ch_pos_mode0: CH_POS_MODE0

        /// Configures the behavior when the signal input of channel %s detects a positive edge.
        @ReadWrite(bits: 26..<28, as: EdgeMode.self)
        public var ch_pos_mode1: CH_POS_MODE1

        /// Configures how the CHn_POS_MODE/CHn_NEG_MODE settings will be modified when the control signal is high.
        @ReadWrite(bits: 20..<22, as: CtrlMode.self)
        public var ch_hctrl_mode0: CH_HCTRL_MODE0

        /// Configures how the CHn_POS_MODE/CHn_NEG_MODE settings will be modified when the control signal is high.
        @ReadWrite(bits: 28..<30, as: CtrlMode.self)
        public var ch_hctrl_mode1: CH_HCTRL_MODE1

        /// Configures how the CHn_POS_MODE/CHn_NEG_MODE settings will be modified when the control signal is low.
        @ReadWrite(bits: 22..<24, as: CtrlMode.self)
        public var ch_lctrl_mode0: CH_LCTRL_MODE0

        /// Configures how the CHn_POS_MODE/CHn_NEG_MODE settings will be modified when the control signal is low.
        @ReadWrite(bits: 30..<32, as: CtrlMode.self)
        public var ch_lctrl_mode1: CH_LCTRL_MODE1
    }

    /// Configuration register 1 for unit 0
    @Register(bitWidth: 32)
    public struct CONF1 {
        /// This register is used to configure the thres0 value for unit %s.
        @ReadWrite(bits: 0..<16)
        public var cnt_thres0: CNT_THRES0

        /// This register is used to configure the thres1 value for unit %s.
        @ReadWrite(bits: 16..<32)
        public var cnt_thres1: CNT_THRES1
    }

    /// Configuration register 2 for unit 0
    @Register(bitWidth: 32)
    public struct CONF2 {
        /// This register is used to configure the thr_h_lim value for unit %s.
        @ReadWrite(bits: 0..<16)
        public var cnt_h_lim: CNT_H_LIM

        /// This register is used to configure the thr_l_lim value for unit %s.
        @ReadWrite(bits: 16..<32)
        public var cnt_l_lim: CNT_L_LIM
    }
}

extension PCNT.UNIT.CONF0 {
    public struct EdgeMode: BitFieldProjectable, RawRepresentable {
        public static let bitWidth = 2

        /// Increase the counter
        public nonisolated(unsafe) static let Increment = Self(rawValue: 0x1)

        /// Decrease the counter
        public nonisolated(unsafe) static let Decrement = Self(rawValue: 0x2)

        public var rawValue: UInt8

        @inlinable @inline(__always)
        public init(rawValue: Self.RawValue) {
            self.rawValue = rawValue
        }
    }
}


extension PCNT.UNIT.CONF0 {
    public struct CtrlMode: BitFieldProjectable, RawRepresentable {
        public static let bitWidth = 2

        /// No modification
        public nonisolated(unsafe) static let Keep = Self(rawValue: 0x0)

        /// decrease
        public nonisolated(unsafe) static let Reverse = Self(rawValue: 0x1)

        public var rawValue: UInt8

        @inlinable @inline(__always)
        public init(rawValue: Self.RawValue) {
            self.rawValue = rawValue
        }
    }
}
