# AddLocation Component - Modification Summary

## ✅ What Has Been Changed

### 1. **Form State Management**
- ✅ Added `serviceInput` state for managing service/amenity input fields
- ✅ Added `menuInput` state for managing menu item input fields  
- ✅ Updated `amenities` structure to include `description` field
- ✅ Updated `menu` structure to include `description` field

### 2. **Event Handlers**
Added four new handler functions:
- `handleAddService()` - Adds a service/amenity to the list
- `handleRemoveService(id)` - Removes a service/amenity from the list
- `handleAddMenuItem()` - Adds a menu item to the list
- `handleRemoveMenuItem(id)` - Removes a menu item from the list

### 3. **Form Submission Logic** 
The `handleSubmitForm()` function now:
- ✅ Validates all required fields before submission
- ✅ Maps business type IDs to category names
- ✅ Formats services with name and description
- ✅ Formats menu items with name, description, and price
- ✅ Sends JSON payload (not FormData) matching your stored procedure parameters

### 4. **Service API Update**
Updated [order.service.ts](order.service.ts) with:
- ✅ TypeScript interface for request payload
- ✅ Proper JSON serialization
- ✅ Better error handling

## 📋 Data Flow to Stored Procedure

```
Form Data ──→ handleSubmitForm ──→ Format to JSON ──→ addNewPlace API
                                           │
                                           ↓
                          {
                            p_name: "Hotel Name",
                            p_address: "123 Main St",
                            p_city: "Hà Nội",
                            p_lat: 21.0285,
                            p_lng: 105.8542,
                            p_categories: ["Hotel", "Restaurant"],
                            p_services: [
                              { name: "Free Parking", description: "Complimentary parking" },
                              { name: "WiFi", description: "High-speed internet" }
                            ],
                            p_menu: [
                              { name: "Cơm Gà", description: "Chicken rice", price: 50000 },
                              { name: "Phở", description: "Beef noodle soup", price: 40000 }
                            ]
                          }
                                           │
                                           ↓
                          /business/add-new-place (POST)
                                           │
                                           ↓
                          Supabase RPC: create_full_place()
                                           │
                                           ↓
                          Returns: place_id (UUID)
```

## 🔧 How to Use

### Step 1: Fill Basic Information
- Enter place name, address, and select city
- Select business types (multiple selections allowed)
- Set latitude/longitude

### Step 2: Add Services & Menu (if applicable)
**Services:**
1. Enter service name in "Tên dịch vụ" field
2. (Optional) Enter description in "Mô tả" field  
3. Click "Thêm" button
4. Service appears in the list below

**Menu Items:**
1. Enter item name in "Tên món ăn" field
2. Enter price in "Giá bán" field
3. (Optional) Enter description
4. Click "Thêm vào danh sách" button
5. Item appears in the grid below

### Step 3: Submit
Click "Tiếp tục" to submit the form. The component will:
1. Validate all required fields
2. Format the data according to stored procedure requirements
3. Send to backend API endpoint
4. Redirect to dashboard on success

## 🚨 Important Category Names

The following category names **MUST** match your `travel.categories` table:

| Form Selection | Database Name | Map Key |
|---|---|---|
| Khách sạn/Lưu trú | `Hotel` | `stay` |
| Nhà hàng/Ẩm thực | `Restaurant` | `food` |
| Tour du lịch | `Tour` | `tour` |
| Vận chuyển | `Transport` | `trans` |

If a category name doesn't exist in the database, the stored procedure will throw an error: `"Category not found"`

## 🔌 Backend Integration Checklist

- [ ] Create `/business/add-new-place` POST endpoint
- [ ] Endpoint calls `create_full_place` stored procedure with request parameters
- [ ] Endpoint returns: `{ success: true, place_id: "uuid-string" }`
- [ ] Backend validates all required fields
- [ ] Backend handles error responses from stored procedure
- [ ] Ensure authenticated requests pass user context (for `auth.uid()`)

## 🧪 Testing Steps

1. **Test with minimal data:**
   - Fill only required fields: name, address, city, one category
   - Submit and verify place is created

2. **Test with services:**
   - Add 2-3 services with names and descriptions
   - Submit and verify services are linked to place

3. **Test with menu items:**
   - Add 2-3 menu items with name, description, and price
   - Submit and verify menu items are created with correct place_id

4. **Test error handling:**
   - Try invalid category name (should error)
   - Try submitting without required fields (should show alert)

## 📝 Notes

- The phone field is collected but **not** sent to stored procedure (for future enhancement)
- Opening hours field is collected but **not** sent (for future enhancement)
- The `img` field for menu items uses a placeholder URL if not provided
- All prices are converted to NUMERIC type for database storage
- Service descriptions default to empty string if not provided
- Menu descriptions default to empty string if not provided

## 🔗 Related Files

- Frontend Component: [src/pages/provider/AddLocation/index.tsx](src/pages/provider/AddLocation/index.tsx)
- Service Layer: [src/services/order.service.ts](src/services/order.service.ts)
- Backend Guide: [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md)

