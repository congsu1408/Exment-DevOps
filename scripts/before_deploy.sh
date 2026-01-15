#!/bin/bash

echo "--- [HOOK] Starting Custom Script ---"

echo "Hook ran successfully at $(date)" > storage/hook_check.txt


echo "--- [HOOK] Finished ---"

#!/bin/bash

echo "--- [SECURITY TEST] STARTING ---"

# TEST 1: Cố tình tạo file vào thư mục của ROOT (Cấm kỵ)
echo "1. Trying to write to /root..."
if touch /root/hacker_was_here.txt; then
    echo "❌ NGUY HIỂM: Hack được vào /root!"
else
    echo "✅ AN TOÀN: Không thể ghi vào /root (Permission denied)."
fi

# TEST 2: Cố tình xóa file cấu hình hệ thống (Ví dụ /etc/hosts)
echo "2. Trying to delete system file (/etc/hosts)..."
if rm -f /etc/hosts; then
    echo "❌ NGUY HIỂM: Đã xóa mất file hệ thống!"
else
    echo "✅ AN TOÀN: Không thể xóa file hệ thống."
fi

# TEST 3: Thử ghi vào nơi được phép (Storage của Laravel)
echo "3. Trying to write to storage..."
if echo "Test OK" > storage/security_check.txt; then
    echo "✅ OK: Ghi được vào storage (Đúng quy trình)."
else
    echo "❌ LỖI: Không ghi được vào storage (Cần xem lại quyền)."
fi

echo "--- [SECURITY TEST] FINISHED ---"