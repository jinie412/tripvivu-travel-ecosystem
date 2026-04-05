# Backend Integration Guide - AddLocation Component

## Overview
The frontend AddLocation component has been updated to work with your PostgreSQL `create_full_place` stored procedure.

## Frontend Changes Made

### 1. **Form Data Structure** 
- Added `description` field to amenities for service descriptions
- Menu items now include `description` field (in addition to existing fields)
- Form data properly maps to stored procedure parameters

### 2. **Submit Handler** (`handleSubmitForm`)
The component now sends the following JSON payload:
```typescript
{
  p_name: string,           // Place name
  p_address: string,        // Detailed address
  p_city: string,          // City/Province
  p_lat: number,           // Latitude
  p_lng: number,           // Longitude
  p_categories: string[],  // Array of category names ['Hotel', 'Restaurant', etc.]
  p_services: [
    { name: string, description: string }  // Service/amenity list
  ],
  p_menu: [
    { name: string, description: string, price: number }  // Menu items
  ]
}
```

### 3. **Business Type Mapping**
Categories are mapped from form IDs to database names:
```typescript
{
  stay: 'Hotel',
  food: 'Restaurant', 
  tour: 'Tour',
  trans: 'Transport'
}
```
**Important**: These names must match exactly with the `travel.categories.name` values in your database.

### 4. **Service & Menu Management**
- Added state for service input: `serviceInput`
- Added state for menu input: `menuInput`
- New handlers: `handleAddService()`, `handleRemoveService()`, `handleAddMenuItem()`, `handleRemoveMenuItem()`

## Backend API Endpoint Required

You need to create a POST endpoint at `/business/add-new-place` that:

### Expected Request Body:
```typescript
interface CreatePlaceRequest {
  p_name: string;
  p_address: string;
  p_city: string;
  p_lat: number;
  p_lng: number;
  p_categories: string[];
  p_services: Array<{ name: string; description: string }>;
  p_menu: Array<{ name: string; description: string; price: number }>;
}
```

### Backend Implementation Example:

**Node.js / Express with Supabase:**
```typescript
import { supabase } from '@/lib/supabase'

app.post('/business/add-new-place', async (req, res) => {
  try {
    const { p_name, p_address, p_city, p_lat, p_lng, p_categories, p_services, p_menu } = req.body;
    
    // Validate required fields
    if (!p_name || !p_address || !p_city || !p_lat || !p_lng || !p_categories?.length) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Call stored procedure
    const { data, error } = await supabase
      .rpc('create_full_place', {
        p_name,
        p_address,
        p_city,
        p_lat,
        p_lng,
        p_categories,
        p_services: p_services || [],
        p_menu: p_menu || []
      });

    if (error) {
      console.error('Stored procedure error:', error);
      return res.status(400).json({ error: error.message });
    }

    res.json({ 
      success: true, 
      place_id: data 
    });
  } catch (error) {
    console.error('Add new place error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

### Response Format:
```typescript
{
  success: true,
  place_id: "uuid-string" // Returned from stored procedure
}
```

## Important Notes

### 1. **Category Names**
- The stored procedure looks up category IDs by name using `LOWER(TRIM(name))` matching
- Category names in the request must exist in `travel.categories` table
- Common categories: `'Hotel'`, `'Restaurant'`, `'Tour'`, `'Transport'`

### 2. **Services & Menu**
- Services can have empty descriptions (defaults to '')
- Menu items can have empty descriptions (defaults to '')
- Prices must be numeric values
- The function associates menu items with the place automatically

### 3. **Authentication**
- The stored procedure uses `auth.uid()` to get the vendor ID
- Ensure your backend is passing authenticated requests
- The vendor_id is NOT needed in the frontend payload

### 4. **Error Handling**
- If a category name doesn't exist, the function raises an exception
- The frontend shows an alert with the error message
- Users should verify category names match your database

## Testing Checklist

- [ ] Test with a single category
- [ ] Test with multiple categories
- [ ] Test with services (amenities)
- [ ] Test with menu items
- [ ] Test with all fields populated
- [ ] Test with minimal required fields only
- [ ] Verify categories are correctly stored in `travel.place_categories`
- [ ] Verify services are correctly stored in `travel.place_services`
- [ ] Verify menu items are correctly stored in `order_sys.food_items`

## File Changes Summary

1. **AddLocation/index.tsx**
   - Added `serviceInput` and `menuInput` state
   - Updated form data structure with `description` fields
   - Added service and menu item handlers
   - Updated `handleSubmitForm` to format data for stored procedure
   - Removed hardcoded VENDOR_ID

2. **order.service.ts**
   - Updated `addNewPlace` function with TypeScript typing
   - Now sends JSON payload instead of FormData
   - Improved error handling

## Troubleshooting

**Issue**: "Category not found" error
- **Solution**: Check that category names in request match `travel.categories.name` exactly (case-insensitive)

**Issue**: Services not being added
- **Solution**: Ensure service state is properly bound to input fields using `value` and `onChange`

**Issue**: Menu items showing undefined prices
- **Solution**: Verify price input is converted to number in `handleSubmitForm` function

