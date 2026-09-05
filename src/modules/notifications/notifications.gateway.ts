import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(NotificationsGateway.name);
  private userSockets = new Map<string, string[]>();

  handleConnection(client: Socket) {
    this.logger.log(`Client connected to WebSocket: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected from WebSocket: ${client.id}`);
    for (const [userId, sockets] of this.userSockets.entries()) {
      const filtered = sockets.filter((id) => id !== client.id);
      if (filtered.length > 0) {
        this.userSockets.set(userId, filtered);
      } else {
        this.userSockets.delete(userId);
      }
    }
  }

  @SubscribeMessage('authenticate')
  handleAuthenticate(client: Socket, payload: { userId: string }) {
    if (payload?.userId) {
      const sockets = this.userSockets.get(payload.userId) || [];
      sockets.push(client.id);
      this.userSockets.set(payload.userId, sockets);
      client.join(`user_${payload.userId}`);
      client.emit('authenticated', { success: true });
    }
  }

  broadcastNewTripRequest(trip: any) {
    if (this.server) {
      this.server.emit('new_trip_request', {
        event: 'NEW_TRIP_AVAILABLE',
        message: 'يوجد طلب مشوار جديد متاح لتقديم العروض',
        trip,
      });
    }
  }

  notifyClientNewBid(clientId: string, payload: any) {
    if (this.server) {
      const price = payload.offerPrice || payload.offer?.offerPrice || '';
      const driverName = payload.driverName || payload.offer?.driverProfile?.user?.fullName || 'أحد السائقين';
      this.server.to(`user_${clientId}`).emit('new_bid_received', {
        event: 'NEW_BID_OFFER',
        title: `🚗 عرض سعر جديد: ${price} ر.س`,
        message: `قدم الكابتن ${driverName} عرضاً بقيمة ${price} ر.س لمشوارك`,
        ...payload,
      });
    }
  }

  notifyDriverBidAccepted(driverUserId: string, payload: any) {
    if (this.server) {
      const contract = payload.contract || payload;
      const pickup = contract?.tripRequest?.pickupAddress || 'نقطة الانطلاق';
      const dropoff = contract?.tripRequest?.dropoffAddress || 'نقطة الوصول';
      const clientName = contract?.client?.fullName || 'العميل';

      this.server.to(`user_${driverUserId}`).emit('bid_accepted', {
        event: 'BID_ACCEPTED_ALERT',
        title: '🎉 مبارك! وافق العميل على عرضك السعري',
        message: `وافق العميل ${clientName} على عرضك لمشوار (${pickup} إلى ${dropoff}). تم إضافة المشوار رسمياً في جدول عملك اليومي.`,
        guidelines: [
          'احترام مواعيد عملك والالتزام بموعد المشوار بدقة',
          'التأكد التام من نظافة السيارة وجاهزيتها التامة لاستقبال العميل',
          'معاملة العميل بأخلاق حسنة ولباقة راقية لرفع تقييمك واستقبال عروض جديدة',
          'تمت إضافة المشوار تلقائياً في جدول عملك اليومي على المنصة',
        ],
        contract,
        ...payload,
      });
    }
  }

  notifyContractCompleted(clientId: string, contractId: string) {
    if (this.server) {
      this.server.to(`user_${clientId}`).emit('trip_completed_rate_driver', {
        event: 'TRIP_COMPLETED_PROMPT_REVIEW',
        message: 'اكتملت مدة التوصيل بنجاح، يرجى تقييم السائق لإنهاء المعاملة.',
        contractId,
      });
    }
  }
}
