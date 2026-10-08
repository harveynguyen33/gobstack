# extras-catalogue/payload/ — the vendored extras payload

`gob extras install` needs **no network**: every skill or workflow it writes is copied
from this directory. One directory per catalogue id:

    payload/<id>/<skill-name>/SKILL.md      # a skill row: one directory per skill
    payload/<id>/…                          # a workflow row: the playbook files verbatim

`mcp` rows carry no payload — their install is the generated mcp.json snippet.

Until a row's payload is vendored, installing it is REFUSED with exit 2 and a named fix
(never a download): vendor the accepted upstream copy here first, respecting the row's
license cell. The placeholder payloads shipped today mark the layout only — the curator
replaces them with the reviewed upstream bytes.
