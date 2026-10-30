# SRA and GEO Data Download Instructions

## 1. Create the Conda Environment

Create a dedicated Conda environment using Python 3.11.

```bash
conda create -n data_download python=3.11
conda activate data_download
```

Ensure that `conda-forge` is configured as a Conda channel.

Check the configured channels:

```bash
conda config --show channels
```

If `conda-forge` is not listed, add it:

```bash
conda config --add channels conda-forge
```

## 2. Install the Required Tools

**MUST** install the following tools in the `data_download` environment:

- `sra-tools` — Download and convert SRA sequencing data.
- `mg-toolkit` — Retrieve study metadata.
- `pysradb` — Retrieve metadata from SRA.

Execute:

```bash
conda install bioconda::sra-tools
conda install bioconda::mg-toolkit
conda install bioconda::pysradb
```

Activate the `data_download` environment before running any commands in the following sections.

## 3. Select a Study

Identify a study hosted by the Gene Expression Omnibus (GEO) or Sequence Read Archive (SRA) before downloading data.

Identify the appropriate accession identifiers for the selected study. (for example GSE210989 - human MRC5 fibroblasts during HCMV infection with AD169)

Use the accession type required by each tool:

- **SRR accession:** Identifies an individual sequencing run.
- **SRP accession:** Identifies an SRA study.
- **PRJNA accession:** Identifies a BioProject.

Do NOT assume that these accession types are interchangeable.

## 4. Set the Output Directory

Navigate to the directory in which the downloaded files or metadata should be stored, or explicitly specify the destination paths in the commands.

Replace example accession identifiers and placeholder paths with values appropriate for the selected study.

## 5. Download and Convert SRA Data to FASTQ

Use `fasterq-dump` to convert the selected SRA run into FASTQ files.

Example:

```bash
fasterq-dump SRR3836347 \
    --split-files \
    --threads 4 \
    --outdir /your/desired/output/directory
```

### Command requirements

- Replace `SRR3836347` with the desired SRR accession.
- Replace `/your/desired/output/directory` with the absolute path to the output directory.
- Use `--split-files` to separate reads when the run contains paired-end data.
- Use `--threads 4` to allocate four threads to the conversion process.
- Ensure that sufficient disk space is available before downloading and converting the data.

## 6. Retrieve Study Metadata

Retrieve metadata for the selected study using one or both of the following methods, depending on the required metadata and available accession identifiers.

### Method 1: Using `mg-toolkit`

Execute:

```bash
mg-toolkit original_metadata -a PRJNA868472
```

**MUST** replace `PRJNA868472` with the appropriate BioProject accession.

### Method 2: Using `pysradb`

Execute:

```bash
pysradb metadata SRP390970 > sra_metadata.tsv
```

**MUST** replace `SRP390970` with the appropriate SRA study accession.


The example command writes the output to `sra_metadata.tsv` in the current working directory.

## 7. Verify the Results

Verify that the expected output files exist and contain data.

Check the FASTQ output directory:

```bash
ls -lh /your/desired/output/directory
```

Check the metadata file:

```bash
ls -lh sra_metadata.tsv
head sra_metadata.tsv
```
## 8. Operational Rules

- **MUST** use the `data_download` Conda environment for all operations described in this document.
- **MUST** use valid accession identifiers for the selected study.
- **MUST** replace all example identifiers and placeholder paths before executing commands.
- **MUST** verify that the required output directories exist and that sufficient disk space is available.
- **MUST** preserve the relationship between downloaded sequencing files and their corresponding study metadata.
- **MUST NOT** assume that downloading metadata also downloads sequencing data.

