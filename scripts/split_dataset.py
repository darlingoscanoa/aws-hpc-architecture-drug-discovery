import os
import math
from pathlib import Path
import shutil

def split_dataset(chunk_size_mb=45):
    """Split the dataset into smaller chunks that CloudShell can handle"""
    source_dir = Path("data/subset")
    chunk_dir = Path("data/chunks")
    
    # Create chunks directory
    chunk_dir.mkdir(parents=True, exist_ok=True)
    
    # Get all files
    all_files = list(source_dir.rglob("*"))
    files_with_size = [(f, f.stat().st_size) for f in all_files if f.is_file()]
    
    # Calculate total size and number of chunks needed
    total_size = sum(size for _, size in files_with_size)
    chunk_size = chunk_size_mb * 1024 * 1024  # Convert MB to bytes
    num_chunks = math.ceil(total_size / chunk_size)
    
    print(f"Total size: {total_size / (1024*1024):.2f} MB")
    print(f"Splitting into {num_chunks} chunks of {chunk_size_mb}MB each")
    
    # Create chunks
    current_chunk = 1
    current_size = 0
    current_chunk_dir = chunk_dir / f"chunk_{current_chunk:03d}"
    current_chunk_dir.mkdir(parents=True, exist_ok=True)
    
    for file_path, file_size in files_with_size:
        # If adding this file would exceed chunk size, move to next chunk
        if current_size + file_size > chunk_size and current_size > 0:
            current_chunk += 1
            current_chunk_dir = chunk_dir / f"chunk_{current_chunk:03d}"
            current_chunk_dir.mkdir(parents=True, exist_ok=True)
            current_size = 0
        
        # Calculate relative path within subset directory
        rel_path = file_path.relative_to(source_dir)
        target_path = current_chunk_dir / rel_path
        
        # Create parent directories if needed
        target_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Copy file
        shutil.copy2(file_path, target_path)
        current_size += file_size
    
    # Create zip files for each chunk
    for chunk_dir in sorted(Path("data/chunks").glob("chunk_*")):
        zip_name = f"{chunk_dir.name}.zip"
        shutil.make_archive(
            str(Path("data/chunks") / chunk_dir.name),
            'zip',
            chunk_dir
        )
        print(f"Created {zip_name}")

if __name__ == "__main__":
    split_dataset()
