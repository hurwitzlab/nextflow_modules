# nextflow_modules

Database of all the Hurwitz lab's Nextflow modules — reusable tool wrappers
(`process` blocks) shared across every lab pipeline, so a bug fix or new
container path only has to happen in one place.

This repo holds modules only. It has no pipeline of its own, no `workflow {}`
entry point, and no config — it's a library that pipeline repos (like
[`viral_inference_benchmark`](https://github.com/hurwitzlab/viral_inference_benchmark))
include from.

## Using these modules in a pipeline

Clone this repo **as a sibling** of the pipeline repo that uses it, under the
same parent directory:

```
some_parent_dir/
  your_pipeline_repo/
  nextflow_modules/
```

Then `include` a module by relative path from wherever your subworkflow or
workflow file lives, e.g. from `your_pipeline_repo/nextflow_pipeline/subworkflows/`:

```groovy
include { genomad } from '../../../nextflow_modules/modules/genomad.nf'
```

Nextflow resolves `include` paths as literal strings at parse time — they
can't be driven by a config variable — so the exact number of `../` depends
on how deep your including file is. Count directory levels up to the shared
parent, then down into `nextflow_modules/modules/`.

**Pinning:** cloning this repo gives you whatever commit is on `main` at
clone time. If you need a pipeline to keep working against a known-good
version regardless of later changes here, checkout a specific tag/commit in
your local clone rather than tracking `main`:

```bash
cd nextflow_modules
git checkout <tag-or-commit>
```

## What a module expects from the pipeline that includes it

Every module reads its container, output directory, and tool options from
`params.*` — it never defines them itself. The consuming pipeline's own
`.config` (or a config it includes) must define, for each module it uses:

- `params.container__<tool>` — path to the tool's container image
- `params.<tool>_outdir` — where terminal output gets published (if the
  process has a `publishDir`)
- `params.<tool>_<option>` — any tool-specific options the module references

The consuming pipeline is also expected to define `withLabel:process_single`,
`withLabel:process_low`, `withLabel:process_medium`, and
`withLabel:process_high` resource selectors (e.g. in its own
`conf/base.config`) — every module tags its process with one of these labels,
but resource amounts are the pipeline's call, not this repo's.

If a module you need references a param your pipeline's config doesn't have
yet, add it — see the module's file for the exact `params.*` names it expects.

## Available modules

| file | processes | tool(s) |
|---|---|---|
| `bbmap.nf` | `bbwrap`, `pileup` | BBMap (read alignment + coverage) |
| `checkv.nf` | `checkv` | CheckV (viral inference quality assessment) |
| `deepvirfinder.nf` | `deepvirfinder` | DeepVirFinder (viral inference) |
| `genomad.nf` | `genomad` | geNomad (viral/plasmid inference) |
| `marvel.nf` | `marvel` | MARVEL (phage bin inference from reads) |
| `samtools.nf` | `sam_to_bam`, `sort_bam`, `index_bam` | Samtools (SAM/BAM conversion, sort, index) |
| `vibrant.nf` | `vibrant` | VIBRANT (viral inference) |
| `virsorter2.nf` | `virsorter2` | VirSorter2 (viral inference) |
| `filter_viral_genomad.nf` | `filter_viral_contigs`, `extract_fasta_viral_selection` | **Work in progress** — shell blocks not yet implemented |

## Adding a new module

1. Read `modules/CLAUDE.md` — house rules for file layout, process block
   structure, shell interpolation style, and `params.*` naming.
2. Copy `modules/TEMPLATE.nf` as a starting point.
3. Work through the checklist at the bottom of `CLAUDE.md` before considering
   it done.
4. In your PR description, list every `params.*` name the new module
   references, so pipeline maintainers know what to add to their own config.
