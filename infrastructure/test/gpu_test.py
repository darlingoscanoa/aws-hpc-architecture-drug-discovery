import torch
import time

def test_gpu():
    print("CUDA Available:", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("GPU Device:", torch.cuda.get_device_name(0))
        
        # Create some test tensors
        x = torch.randn(1000, 1000).cuda()
        y = torch.randn(1000, 1000).cuda()
        
        # Perform matrix multiplication to stress GPU
        for i in range(10):
            z = torch.matmul(x, y)
            print(f"Iteration {i+1}: Matrix multiplication completed")
            time.sleep(2)  # Wait to see GPU metrics

if __name__ == "__main__":
    test_gpu()
