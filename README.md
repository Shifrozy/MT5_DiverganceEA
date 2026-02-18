# MT5 Sniper Divergence EA

A high-performance **MetaTrader 5 Expert Advisor** designed for precision trading using **RSI Divergences** validated by **Supply/Demand** and **Support/Resistance** zones.

![MetaTrader 5](https://img.shields.io/badge/MT5-MQ5-blue.svg)
![Trading](https://img.shields.io/badge/Strategy-Divergence-green.svg)
![Risk Management](https://img.shields.io/badge/Risk-Automated-red.svg)

## 🚀 Key Features

- **Advanced Divergence Detection**: Identifies Regular and Hidden RSI divergences (Class A) with high precision across multiple timeframes.
- **Multi-Timeframe (MTF) Scanning**: Automatically scans Daily, H4, H1, M30, M15, and M5 timeframes for signals while executing trades on a lower timeframe (e.g., M1) for sniper-like entries.
- **Dual Zone Validation**:
  - **Support & Resistance**: Real-time detection of significant price levels based on historical touches.
  - **Supply & Demand**: Identification of impulsive move origins and consolidation zones.
- **Sniper Entry Logic**: Zero-lag execution phase. The EA waits for price to touch a validated zone after a divergence signal is detected.
- **Robust Risk Management**:
  - ATR-based or Fixed Pips Stop Loss.
  - Automatic Break-Even triggering at user-defined profit levels.
  - Dynamic Take Profit following the EMA 50 of the next lower timeframe.
  - Configurable Risk Percentage per trade.
- **Visual Intelligence**: Draws divergence lines and validated zones directly on the chart for transparency and manual monitoring.

## 🛠 Installation

1. Open your MetaTrader 5 Terminal.
2. Navigate to `File` -> `Open Data Folder`.
3. Go to `MQL5` -> `Experts`.
4. Copy the `DivergenceTrader_EA_v3.mq5` file into this folder.
5. Restart MT5 or right-click `Experts` in the Navigator and select `Refresh`.
6. Attach the EA to your desired chart (recommended: XAUUSD, EURUSD, GBPUSD).

## ⚙️ Configuration

The EA comes with highly customizable input parameters:

| Group | Parameter | Description |
|-------|-----------|-------------|
| **Trading Mode** | `TradingMode` | Toggle between Automatic trading and Manual (Signal only) mode. |
| **MTF Scanning** | `Scan_XX` | Enable/Disable specific timeframes for scanning. |
| **RSI Settings** | `RSI_Period` | Standard RSI period (Default: 14). |
| **Zone Validation** | `ZoneFilter` | Filter signals by S/R, S/D, or both. |
| **Risk Mgt** | `RiskPercent` | Set risk per trade as a percentage of your balance. |

## 📈 Strategy Overview

1. **Scan**: The EA scans higher timeframes for RSI divergences.
2. **Validate**: Once a divergence is found, it checks if the price is currently within or near a Supply/Demand or Support/Resistance zone.
3. **Execute**: It drops down to the Entry Timeframe (default M1) and executes the trade immediately upon zone contact to minimize drawdown and maximize R:R.
4. **Manage**: Moves SL to break-even once the target is reached and trails the profit using dynamic EMA levels.

## ⚠️ Disclaimer

Trading Forex and CFDs involves significant risk. This EA is provided for educational and informational purposes. Always test on a demo account before trading with real capital.

---
**Developed by:** Hassan Cheema
**Version:** 3.0
