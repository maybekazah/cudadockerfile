import cv2

from cv2 import cudacodec
from copy import deepcopy


video_path = ""

def open_with_nvdec(self):

    reader = cudacodec.createVideoReader(video_path)

    while self.context.get('run', True):
        ok, gpu_mat = reader.nextFrame()
        if not ok:
            break

        try:
            # ресайз входного кадра
            gpu_resized = cv2.cuda.resize(
                gpu_mat,
                (1920, 1080),
                interpolation=cv2.INTER_LINEAR
            )

        except cv2.error as e:
            print(f"CUDA-resize не поддерживается, ресайз на CPU: {e}")
            cpu_tmp = gpu_mat.download()
            cpu_resized = cv2.resize(cpu_tmp, (1920, 1080), interpolation=cv2.INTER_LINEAR)
            cpu_frame = cpu_resized
        else:
            cpu_frame = gpu_resized.download()

        frame = cpu_frame
        original_frame = deepcopy(cpu_frame)
        
        return frame, original_frame