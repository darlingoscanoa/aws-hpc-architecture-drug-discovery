# Dataset Preparation

## Human Protein Atlas Dataset

We are using a balanced subset of the Human Protein Atlas Image Classification dataset for our drug discovery pipeline.

### Dataset Statistics
- Total samples: 498
- Classes: 28 (all classes represented)
- Images per sample: 4 (red, green, blue, yellow channels)
- Total images: 1,992

### Data Location
The processed dataset is stored in:
```
s3://hpc-drug-discovery-data-2025/human_protein_atlas/
```

### Directory Structure
```
human_protein_atlas/
├── train/
│   ├── [image_id]_blue.png
│   ├── [image_id]_green.png
│   ├── [image_id]_red.png
│   └── [image_id]_yellow.png
└── subset_statistics.txt
```

### Data Processing
The dataset was processed to ensure:
1. Balanced representation across all 28 protein classes
2. Preservation of all four color channels per sample
3. Consistent image quality and format

### Usage in Training
To use this dataset in your training scripts:
1. Configure AWS credentials
2. Use the S3 path: s3://hpc-drug-discovery-data-2025/human_protein_atlas/
3. Images are organized by their unique ID and color channel
