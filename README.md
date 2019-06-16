# on-the-money
A home accounting database. For using with ANZ and Kiwibank personal banking exports.
- Export banking files from your bank (this is a manual step through online personal banking)
- Import files (one-at-a-time) into Postgres using Python scripts
- Build up and apply rules that categorise bank transactions into accounts
- Create summary views of the data for reporting and visualisation

Developed using Visual Studio Code and DBeaver on macOS 10.13 / Win 10 using Python 3.6.5 (including Pandas and Anaconda) with Postgres 10.4.

Support export file types:
ANZ: Excel, OFX
Kiwibank: OFX

The project is pre-alpha.

Future plans for API: use Flask to wrap Python scripts in Restful API

Future plans for UI: not known

