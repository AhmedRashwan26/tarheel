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

  notifyClientNewBid(clientId: string, offer: any) {
    if (this.server) {
      this.server.to(`user_${clientId}`).emit('new_bid_received', {
        event: 'NEW_BID_OFFER',
        message: `تم تقديم عرض سعر جديد بقيمة ${offer.offerPrice} ر.س لمشوارك`,
        offer,
      });
    }
  }

  notifyDriverBidAccepted(driverUserId: string, contract: any) {
    if (this.server) {
      this.server.to(`user_${driverUserId}`).emit('bid_accepted', {
        event: 'BID_ACCEPTED_ALERT',
        message: 'تهانينا! قام العميل بقبول عرضك السعري. يرجى الالتزام بالموعد والمكان المحددين.',
        contract,
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
