<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5 -->
# Global Codex Pharmaceutical Framework v5

These rules apply to every project. Project-level `AGENTS.md` files may add
project facts, constraints, and commands, but must not silently weaken safety,
authorization, routing, or validation requirements.

## Mandatory classification
Classify every request before choosing an execution strategy.

### Trivial work
A task is trivial only when every condition below is true:
- one narrow, clearly stated objective;
- affects at most one file or one isolated location;
- cause, required change, and expected result are already known;
- no meaningful design decision or uncertain investigation;
- does not change externally consumed behavior or shared contract;
- does not involve any mandatory non-trivial trigger;
- failure would have only local, low-impact consequences;
- immediately reversible with one small change;
- one focused, deterministic check can validate it.

### Mandatory non-trivial triggers
Classify as non-trivial when it involves:
- unknown or uncertain root cause;
- more than one component, active ingredient, or pharmaceutical form;
- coordinated changes across multiple files or master formulas;
- architecture, data flow, shared state, or regulatory standards;
- public APIs, schemas, or regulatory documents (ANVISA / RDC 67/2007);
- authentication, security boundaries, or controlled substances (Portaria 344/98);
- persistent data, database writes, or stability records;
- sterile preparations, high potency, or hormone containment;
- dependency addition, removal, or supply-chain qualification;
- backward compatibility or platform matrix;
- destructive or difficult-to-reverse actions.

## Routing non-trivial work
Estimate a 0-100 complexity/risk score:

| Factor | Max |
| --- | ---: |
| Scope and change size | 10 |
| Components and ingredients | 8 |
| Uncertainty and investigation | 10 |
| Architectural and formulation impact | 10 |
| Security and regulatory compliance | 12 |
| Data, state, or stability records | 10 |
| Concurrency or quality control | 8 |
| Operational or production impact | 10 |
| Irreversibility | 6 |
| Testing difficulty | 6 |
| Compatibility or excipient risk | 5 |
| External integration or clinical complexity | 5 |

Route each bounded unit of work independently:
- 0-34: Luna tier.
- 35-69: Terra tier.
- 70-100: Sol tier.

### Risk floors
Risk floors override numeric score:
- At least Terra: high-potency drugs, hormones, sterile formulations, controlled substances (Portaria 344/98), salt/base stoichiometry calculations, and BUD stability determinations.
- Sol for critical portion: quality deviation investigations, sterility failures, toxic precipitants, or microbiological contamination.
<!-- CODEX-GLOBAL-FRAMEWORK:END v5 -->
