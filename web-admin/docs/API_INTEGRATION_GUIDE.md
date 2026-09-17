# Hướng dẫn tích hợp API và cấu hình ENV

Tài liệu này mô tả 2 việc:

1. Mới clone code về thì tạo ENV như thế nào.
2. Tạo một API mới và sử dụng đúng chuẩn trong dự án.

Lưu ý: Dự án hiện tại dùng API thật 100%, không còn dùng mock mode.

---

## 1) Khi mới clone code về: tạo ENV như thế nào

### Bước 1: Cài dependencies

```bash
npm install
```

### Bước 2: Tạo file ENV

Bạn chỉ dùng một file `.env` là hoàn toàn ổn.

Nếu dùng macOS/Linux:

```bash
cp .env.example .env
```

Nếu dùng PowerShell trên Windows:

```powershell
Copy-Item .env.example .env
```

### Bước 3: Chỉnh giá trị ENV

Mở file `.env` và cập nhật:

```env
VITE_API_URL=http://localhost:8080/api
VITE_API_TIMEOUT=15000
```

Ý nghĩa:

- `VITE_API_URL`: Base URL backend.
- `VITE_API_TIMEOUT`: timeout cho mỗi request (ms).

### Bước 4: Chạy project

```bash
npm run dev
```

Nếu thay đổi ENV trong lúc đang chạy, cần restart dev server.

Ghi chú thêm:

- `.env` là đủ dùng cho nhu cầu hiện tại của bạn.
- Chỉ cần `.env.development` khi bạn muốn tách cấu hình riêng cho môi trường dev.

---

## 2) Quy trình tạo một API mới theo chuẩn

Ví dụ: tạo API quản lý Category (đơn giản để team mới dễ áp dụng).

### Bước 1: Tạo type trong `src/types`

Tạo file `src/types/category.ts`:

```ts
export interface Category {
  id: string;
  name: string;
  description?: string;
}
```

### Bước 2: Tạo service trong `src/services`

Tạo file `src/services/categoryAPI.ts`:

```ts
import { Category } from "../types/category";
import { apiClient, extractResponseData } from "./apiClient";

export const categoryAPI = {
  // API danh sách category: mong đợi backend trả về Category[]
  getCategories: async (): Promise<Category[]> => {
    const response = await apiClient.get<Category[] | { data: Category[] }>(
      "/categories",
    );
    return extractResponseData<Category[]>(response);
  },

  // API chi tiết category: trả null nếu không tìm thấy hoặc backend lỗi
  getCategoryById: async (id: string): Promise<Category | null> => {
    try {
      const response = await apiClient.get<Category | { data: Category }>(
        `/categories/${id}`,
      );
      return extractResponseData<Category>(response);
    } catch {
      return null;
    }
  },

  // API tạo mới category
  createCategory: async (
    payload: Pick<Category, "name" | "description">,
  ): Promise<Category> => {
    const response = await apiClient.post<Category | { data: Category }>(
      "/categories",
      payload,
    );
    return extractResponseData<Category>(response);
  },
};
```

Giải thích nhanh:

- `extractResponseData` giúp team dùng chung 1 cách đọc response (`data` hoặc trả thẳng).
- `try/catch` trong `getCategoryById` giúp UI xử lý trường hợp not found gọn hơn.
- Luôn trả về kiểu dữ liệu ổn định (`Category[]`, `Category | null`, `Category`) để component dễ dùng.

### Bước 3: Dùng trong page/hook

Nếu dùng React Query:

```ts
import { useQuery } from "@tanstack/react-query";
import { categoryAPI } from "@/services/categoryAPI";

export const useCategories = () => {
  return useQuery({
    queryKey: ["categories"],
    queryFn: () => categoryAPI.getCategories(),
  });
};
```

### Bước 4: Mapping endpoint với backend

Thống nhất trước với backend:

- `GET /categories`
- `GET /categories/:id`
- `POST /categories`

Khuyến nghị backend trả về 1 trong 2 format sau (để đồng bộ với `extractResponseData`):

1. Trả thẳng object/array
2. Bọc trong `{ data: ... }`

---

## 3) Quy tắc bắt buộc để không lỗi về sau

- Không gọi `axios` trực tiếp trong page/component. Luôn gọi qua file service.
- Không hard-code URL backend trong service. Luôn dùng `apiClient` + ENV.
- Không dùng `any` trong request/response types.
- Nếu backend đổi schema response, cập nhật service parser trước khi sửa UI.

---

## 4) Checklist trước khi merge

- Đã tạo/cập nhật type trong `src/types`.
- Đã tạo service mới trong `src/services`.
- Đã test gọi backend thật trên local.
- Đã kiểm tra loading/error state ở màn hình sử dụng API.
- Đã chạy `npm run build`.

---

## 5) Mẫu ENV cho môi trường

### Local (đang dùng)

```env
VITE_API_URL=http://localhost:8080/api
VITE_API_TIMEOUT=15000
```

### Production (tham khảo)

```env
VITE_API_URL=https://api.your-domain.com/api
VITE_API_TIMEOUT=20000
```

Khuyến nghị: Không commit file chứa secret thật (ví dụ token/private key). Chỉ commit `.env.example`.
