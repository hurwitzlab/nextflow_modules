# Module conventions (nextflow_modules)

Rules for writing/editing `.nf` module files in this repo, derived from the
existing modules (bbmap, checkv, deepvirfinder, genomad, marvel, samtools,
vibrant, virsorter2). Follow these for any new or edited module. See
`TEMPLATE.nf` in this directory for a copy-paste starting point.

This repo is shared across every pipeline in the lab — a module here has no
one "parent" pipeline. Don't hardcode assumptions about a specific pipeline's
directory layout or config file names; only assume the `params.*` contract
described below.

## File layout

- One file per tool, named `<tool>.nf` (lowercase, matches the binary/tool name).
- A tool with multiple steps gets multiple `process` blocks in the same file
  (e.g. `bbmap.nf` has `bbwrap` + `pileup`, `samtools.nf` has `sam_to_bam` +
  `sort_bam` + `index_bam`), not one file per process.
- File starts with `#!/usr/bin/env nextflow`, then a blank line.
- Do not add `nextflow.enable.dsl=2` to module files — that belongs in the
  consuming pipeline's workflows/subworkflows, not individual modules.

## Process block

- One-line `//` comment directly above each `process` describing what it does
  in plain terms ("Infer viral sequences using X", "Align reads to contigs with X").
- Process name: lowercase, matches the tool/subcommand (`genomad`, `checkv`,
  `bwa_index`). Use `snake_case`, not `camelCase`.
- First line inside the block: `label "process_<tier>"` — one of `process_single`,
  `process_low`, `process_medium`, `process_high`. Pick the tier by the tool's
  actual resource footprint; when in doubt use `process_medium`. The consuming
  pipeline is expected to define these tiers via `withLabel:` selectors in its
  own resource config (e.g. a `conf/base.config`) — modules only apply the label,
  never define what it resolves to.
- Next line: `container "${params.container__<tool>}"`.
- If the process produces a result meant to persist (final per-sample output,
  a report, a summary), add:
  `publishDir "${params.<tool>_outdir}", mode: 'copy'`
  right after `container`. Skip `publishDir` for purely intermediate steps
  that only feed the next process (e.g. `bbwrap`'s raw alignment, `sam_to_bam`/
  `sort_bam`'s intermediate `.bam`).

## Input / output

- Per-sample data flows as a tuple: `tuple val(sampleid), path(...)`.
- Reference databases / shared resources are separate `path(...)` inputs, not
  folded into the sample tuple (see `genomad`, `checkv`, `virsorter2`).
- Every output gets an explicit, descriptive `emit:` name — never leave it
  unnamed. Match the semantics, not the tool name: `viral_inferences`,
  `quality_assessment`, `count_table`, `sam_file`, `indexed_sequence`.
- Preserve `sampleid` through the output tuple whenever the process is
  per-sample, so downstream processes can keep joining on it.
- Be consistent about trailing slashes on directory-path outputs across a
  module set (pick one style, e.g. no trailing `/`, and use it everywhere).

## Shell block

- Use `shell:` + a `'''...'''` block with `!{...}` interpolation for
  Nextflow variables — this is the standard for every module here. Do **not**
  use `script:` + `"""..."""` with `${...}` interpolation.
- Never put a `#` comment on a line that ends in a `\` continuation inside a
  shell block — the shell sees `\` + comment and breaks the command. Put
  comments on their own line above the command, or drop them.
- Thread/CPU count always comes from `task.cpus`, passed as whatever flag or
  key the tool uses (`-t`, `-c`, `-j`, `--threads`, `threads=`) — never
  hardcode a thread count.
- Always close every `process { ... }` block. Read the file back after
  writing it and confirm the final `}` is present — this repo has had modules
  committed with a missing closing brace.

## Params naming (used from `params.*` inside modules)

- Container: `container__<tool>` (double underscore).
- Output dir: `<tool>_outdir`.
- Tool options: `<tool>_<option>`, snake_case, matching the tool's own flag
  name where reasonable (e.g. `bbmap_kfilter`, `coverm_minident`,
  `vibrant_minlength`).
- Shared/global options (not tool-specific) go unprefixed, e.g.
  `params.viralinference_minlength` when several viral-inference tools share
  the same cutoff.
- Every param a module references is a contract with whichever pipeline
  includes it: that pipeline's own config (or a config it includes) must
  define it under `params { ... }`. Modules never define their own params —
  don't invent a param name in a module without documenting that the
  consuming pipeline needs to add it.

## Checklist before considering a module done

1. Shebang, comment, process name, label, container, (publishDir if terminal output).
2. Inputs as `tuple val(sampleid), path(...)` + separate db paths as needed.
3. Outputs all named via `emit:`, `sampleid` preserved.
4. `shell:` + `!{...}`, no `${...}` mixed in.
5. Threads from `task.cpus`.
6. No comments on `\`-continued shell lines.
7. Every `process` block's braces balance — count `{` vs `}`.
8. Every `params.*` the module references is listed in the PR/commit description
   so pipeline maintainers know what to add to their own config.
