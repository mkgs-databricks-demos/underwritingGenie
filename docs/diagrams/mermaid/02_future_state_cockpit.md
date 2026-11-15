# Future State Cockpit

```mermaid
flowchart LR
  B[Broker / AE submits] --> I[Genie One intake skill<br/>checklist in UC]
  I -->|Blocked| D[Draft precise broker request]
  I -->|Ready| RF[Governed rating function<br/>UC SQL table function]
  RF --> S[(nb_quote_scenarios)]
  S --> ART[Interactive New Business Quote<br/>Genie Artifact]
  ART --> UW[Underwriter decides + notes]
  UW --> AE[AE / broker proposal PDF]
  S --> MV[Metric views<br/>loss ratio, premium at risk]
  MV --> FIN[Finance / CFO questions in Genie]
```
