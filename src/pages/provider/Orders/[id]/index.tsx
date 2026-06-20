import React from 'react';
import Button from '../../../../components/UI/Button';
import ConfirmDialog from '../../../../components/UI/ConfirmDialog';
import { Mail, Phone, User, CheckCircle, XCircle, Clock } from 'lucide-react';
import { useNavigate, useParams } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { getOrderDetail, updateOrderStatus } from '@/services/order.service';

const OrderDetailPage: React.FC = () => {
   const navigate = useNavigate();
   const { id } = useParams();

   const [orderData, setOrderData] = useState<any>(null);
   const [loading, setLoading] = useState(true);
   const [error, setError] = useState<string | null>(null);
   const [updating, setUpdating] = useState(false);
   const [confirmDialog, setConfirmDialog] = useState<{ newStatus: string; message: string } | null>(null);

   const confirmLabels: Record<string, string> = {
      processing: 'Xác nhận đơn hàng này?',
      completed: 'Xác nhận hoàn thành đơn hàng?',
      cancelled: 'Bạn chắc chắn muốn hủy đơn hàng này?',
   };

   const requestUpdateStatus = (newStatus: string) => {
      setConfirmDialog({ newStatus, message: confirmLabels[newStatus] ?? 'Xác nhận thao tác?' });
   };

   const handleUpdateStatus = async () => {
      if (!orderData || !confirmDialog) return;
      const { newStatus } = confirmDialog;
      setConfirmDialog(null);
      setUpdating(true);
      try {
         await updateOrderStatus(orderData.id, newStatus);
         const statusMap: { [key: string]: string } = {
            'pending': 'Chờ xác nhận',
            'processing': 'Đang chuẩn bị',
            'completed': 'Hoàn thành',
            'cancelled': 'Đã hủy',
         };
         setOrderData((prev: any) => ({ ...prev, status: newStatus, statusText: statusMap[newStatus] || newStatus }));
      } catch (err) {
         console.error('Không thể cập nhật trạng thái:', err);
      } finally {
         setUpdating(false);
      }
   };

   useEffect(() => {
      const fetchOrderDetail = async () => {
         try {
            const data = await getOrderDetail(id!);
            
            // Transform API response to match component structure
            const statusMap: { [key: string]: string } = {
               'pending': 'Chờ xác nhận',
               'processing': 'Đang chuẩn bị',
               'completed': 'Hoàn thành',
               'cancelled': 'Đã hủy',
            };

            const transformedData = {
               id: data.order_id,
               status: data.status,
               statusText: statusMap[data.status] || data.status,
               customer: {
                  name: data.customer_name,
                  phone: data.phone,
                  email: data.email
               },
               timeInfo: {
                  ordered: new Date(data.ordered_time).toLocaleString('vi-VN'),
                  expected: new Date(new Date(data.ordered_time).getTime() + 30 * 60000).toLocaleString('vi-VN') // +30 minutes as estimate
               },
               items: data.foods.map((food: any) => ({
                  name: food.food_name,
                  quantity: food.quantity,
                  price: food.price,
                  itemTotal: food.price * food.quantity
               })),
               note: data.notes || 'Không có ghi chú',
               total: data.foods.reduce((sum: number, food: any) => sum + (food.price * food.quantity), 0)
            };

            setOrderData(transformedData);
         } catch (error) {
            console.error('Error fetching order detail:', error);
            setError('Không thể tải chi tiết đơn hàng');
         } finally {
            setLoading(false);
         }
      };

      if (id) fetchOrderDetail();
   }, [id]);
   if (loading) return <div>Loading...</div>;
   if (!orderData) return <div>No data</div>;
   return (
      <>
         {confirmDialog && (
            <ConfirmDialog
               message={confirmDialog.message}
               confirmColor={
                  confirmDialog.newStatus === 'cancelled' ? '#ef4444'
                  : confirmDialog.newStatus === 'completed' ? '#10b981'
                  : undefined
               }
               onConfirm={handleUpdateStatus}
               onCancel={() => setConfirmDialog(null)}
            />
         )}
         <div style={{ padding: '0 20px' }}>
            {/* Breadcrumb & Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '32px' }}>
               <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#94a3b8', marginBottom: '12px' }}>
                     <span style={{ cursor: 'pointer' }} onClick={() => navigate('/orders')}>Đơn đặt món</span>
                     <span>/</span>
                     <span style={{ color: '#1e293b', fontWeight: '700' }}>#{orderData.id}</span>
                  </div>
                  <h2 style={{ fontSize: '32px', fontWeight: '800', color: '#1e293b', marginBottom: '8px' }}>#{orderData.id}</h2>
                  <p style={{ fontSize: '15px', color: '#64748b' }}>Chi tiết đơn hàng {orderData.statusText.toLowerCase()}</p>
               </div>
               <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 16px', background: '#F0F9FF', borderRadius: '12px', color: orderData.status === 'confirm' ? '#3b82f6' : '#f59e0b', fontSize: '13px', fontWeight: '700' }}>
                  <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: orderData.status === 'confirm' ? '#3b82f6' : '#f59e0b' }}></div>
                  {orderData.statusText}
               </div>
            </div>

            {/* Time Info Horizontal Bar */}
            <div style={{ display: 'flex', gap: '24px', marginBottom: '32px' }}>
               <div style={{ flex: 1, background: 'white', borderRadius: '24px', padding: '20px 24px', border: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', gap: '16px', boxShadow: '0 2px 4px rgba(0,0,0,0.02)' }}>
                  <div style={{ width: '48px', height: '48px', borderRadius: '14px', background: '#F0FDF4', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#16a34a' }}>
                     <Clock size={20} />
                  </div>
                  <div>
                     <p style={{ fontSize: '11px', color: '#94a3b8', fontWeight: '800', textTransform: 'uppercase', marginBottom: '4px', letterSpacing: '0.5px' }}>Thời gian khách đặt</p>
                     <p style={{ fontSize: '16px', fontWeight: '800', color: '#1e293b' }}>{orderData.timeInfo.ordered}</p>
                  </div>
               </div>
               <div style={{ flex: 1, background: 'white', borderRadius: '24px', padding: '20px 24px', border: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', gap: '16px', boxShadow: '0 2px 4px rgba(0,0,0,0.02)' }}>
                  <div style={{ width: '48px', height: '48px', borderRadius: '14px', background: '#EFF6FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
                     <Clock size={20} />
                  </div>
                  <div>
                     <p style={{ fontSize: '11px', color: '#94a3b8', fontWeight: '800', textTransform: 'uppercase', marginBottom: '4px', letterSpacing: '0.5px' }}>Dự kiến khách sẽ đến</p>
                     <p style={{ fontSize: '16px', fontWeight: '800', color: '#1e293b' }}>{orderData.timeInfo.expected}</p>
                  </div>
               </div>
            </div>

            <div style={{ display: 'flex', gap: '32px' }}>
               {/* Left: Customer Info */}
               <div style={{ width: '320px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
                  <div style={{
                     background: 'white',
                     borderRadius: '24px',
                     padding: '24px',
                     border: '1px solid #F1F5F9',
                     boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05)'
                  }}>
                     <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: '#F0F9FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6' }}>
                           <User size={20} />
                        </div>
                        <h5 style={{ fontSize: '12px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Thông tin khách hàng</h5>
                     </div>

                     <div style={{ padding: '20px', background: '#F8FAFC', borderRadius: '20px', marginBottom: '24px' }}>
                        <h4 style={{ fontSize: '20px', fontWeight: '800', color: '#1e293b' }}>{orderData.customer.name}</h4>
                     </div>

                     <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                        <div style={{ padding: '16px', borderRadius: '16px', border: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', gap: '14px', transition: '0.2s' }}>
                           <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'white', border: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748b' }}>
                              <Phone size={16} />
                           </div>
                           <div>
                              <p style={{ fontSize: '11px', color: '#94a3b8', fontWeight: '800', textTransform: 'uppercase', marginBottom: '2px' }}>Số điện thoại</p>
                              <p style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{orderData.customer.phone}</p>
                           </div>
                        </div>
                        <div style={{ padding: '16px', borderRadius: '16px', border: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', gap: '14px' }}>
                           <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'white', border: '1px solid #F1F5F9', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748b' }}>
                              <Mail size={16} />
                           </div>
                           <div>
                              <p style={{ fontSize: '11px', color: '#94a3b8', fontWeight: '800', textTransform: 'uppercase', marginBottom: '2px' }}>Địa chỉ Email</p>
                              <p style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b', maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis' }}>{orderData.customer.email}</p>
                           </div>
                        </div>
                     </div>
                  </div>
               </div>

               {/* Middle: Order Items */}
               <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '32px' }}>
                  <div style={{ background: 'white', borderRadius: '24px', overflow: 'hidden', border: '1px solid #F1F5F9' }}>
                     <div style={{ padding: '24px 32px', borderBottom: '1px solid #F1F5F9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <h5 style={{ fontSize: '13px', fontWeight: '800', color: '#1e293b' }}>CHI TIẾT MÓN ĐÃ ĐẶT</h5>
                        <span style={{ fontSize: '12px', color: '#94a3b8', fontWeight: '600' }}>{orderData.items.length} món</span>
                     </div>
                     <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                           <tr style={{ background: '#FCFCFD', textAlign: 'left' }}>
                              <th style={{ padding: '16px 32px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase' }}>Tên món</th>
                              <th style={{ padding: '16px 32px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', textAlign: 'center' }}>Số lượng</th>
                              <th style={{ padding: '16px 32px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', textAlign: 'right' }}>Giá</th>
                              <th style={{ padding: '16px 32px', fontSize: '11px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', textAlign: 'right' }}>Thành tiền</th>
                           </tr>
                        </thead>
                        <tbody>
                           {orderData.items.map((item: any, idx: any) => (
                              <tr key={idx} style={{ borderBottom: '1px solid #F8FAFC' }}>
                                 <td style={{ padding: '20px 32px', fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>{item.name}</td>
                                 <td style={{ padding: '20px 32px', fontSize: '14px', color: '#64748b', textAlign: 'center' }}>{item.quantity}</td>
                                 <td style={{ padding: '20px 32px', fontSize: '14px', fontWeight: '700', color: '#1e293b', textAlign: 'right' }}>{item.price.toLocaleString('vi-VN')} ₫</td>
                                 <td style={{ padding: '20px 32px', fontSize: '14px', fontWeight: '700', color: '#3b82f6', textAlign: 'right' }}>{item.itemTotal.toLocaleString('vi-VN')} ₫</td>
                              </tr>
                           ))}
                        </tbody>
                     </table>
                     <div style={{ padding: '32px', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: '24px', background: '#F8FAFC' }}>
                        <span style={{ fontSize: '16px', fontWeight: '800', color: '#64748b' }}>Tổng cộng:</span>
                        <span style={{ fontSize: '24px', fontWeight: '800', color: '#3b82f6' }}>{orderData.total.toLocaleString('vi-VN')} ₫</span>
                     </div>
                  </div>
               </div>

               {/* Right: Notes & Actions */}
               <div style={{ width: '320px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
                  {/* Customer Note */}
                  <div style={{ background: 'white', borderRadius: '24px', padding: '24px', border: '1px solid #F1F5F9' }}>
                     <h5 style={{ fontSize: '12px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', marginBottom: '16px' }}>Ghi chú của khách</h5>
                     <div style={{ padding: '16px', background: '#FEFCE8', borderRadius: '16px', border: '1px solid #FEF9C3', color: '#854d0e', fontSize: '14px', fontWeight: '600', fontStyle: 'italic' }}>
                        {orderData.note}
                     </div>
                  </div>

                  {/* Actions */}
                  <div style={{ background: 'white', borderRadius: '24px', padding: '24px', border: '1px solid #F1F5F9', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                     <h5 style={{ fontSize: '12px', fontWeight: '800', color: '#94a3b8', textTransform: 'uppercase', marginBottom: '4px' }}>Thao tác đơn hàng</h5>

                     {orderData.status === 'pending' && (
                        <>
                           <Button fullWidth disabled={updating} style={{ borderRadius: '12px', gap: '8px', padding: '14px' }} onClick={() => requestUpdateStatus('processing')}>
                              <CheckCircle size={18} /> Xác nhận
                           </Button>
                           <Button variant="outline" fullWidth disabled={updating} style={{ borderRadius: '12px', gap: '8px', padding: '14px', color: '#ef4444', borderColor: '#FEE2E2', background: 'transparent' }} onClick={() => requestUpdateStatus('cancelled')}>
                              <XCircle size={18} /> Hủy đơn
                           </Button>
                        </>
                     )}

                     {orderData.status === 'processing' && (
                        <Button fullWidth disabled={updating} style={{ borderRadius: '12px', gap: '8px', padding: '14px', background: '#10b981' }} onClick={() => requestUpdateStatus('completed')}>
                           <CheckCircle size={18} /> Hoàn thành
                        </Button>
                     )}

                  </div>

               </div>
            </div>
         </div>
      </>
   );
};

export default OrderDetailPage;
