# Conversation Recovery System

## Docker Conversation Location

Docker conversations are stored in: `claude-code-config` volume under `/config/projects/-workspace/`

## Bank Nifty Session Found

**Container Info:**
- Container Name: claude-task-claude-autonomous-bank-20250711-023049
- Session ID: 20250711-023049
- Project: bank-nifty-options-backtesting
- Created: 2025-07-10T21:00:49Z

**Key Conversation IDs:**
- 54f1b9b6-a2a2-4a91-9836-f98330b15c20 (main bank-nifty dashboard work)
- 42ec0df6-e93f-43b9-9bfa-94bfefd72a37
- And several others in the Docker volume

## What You Were Working On

Based on the recovered data:
- Bank Nifty options backtesting project
- Processing tick data and converting to parquet files
- Dashboard comparison between raw ticks and parquet data
- Project location: `/workspace/bank-nifty-options-backtesting/`

## Next Steps

The conversation backup system will be implemented to automatically save all Docker conversations to your Mac.