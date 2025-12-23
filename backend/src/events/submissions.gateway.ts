import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*', // В продакшене настроить правильно
    credentials: true,
  },
  namespace: '/submissions',
})
export class SubmissionsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private logger = new Logger(SubmissionsGateway.name);

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Subscribe to submission updates
   */
  @SubscribeMessage('subscribe')
  handleSubscribe(
    @MessageBody() data: { submissionId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { submissionId } = data;
    
    if (!submissionId) {
      return { error: 'submissionId is required' };
    }

    const room = `submission:${submissionId}`;
    client.join(room);
    
    this.logger.log(`Client ${client.id} subscribed to ${room}`);
    
    return { subscribed: true, submissionId };
  }

  /**
   * Unsubscribe from submission updates
   */
  @SubscribeMessage('unsubscribe')
  handleUnsubscribe(
    @MessageBody() data: { submissionId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { submissionId } = data;
    
    if (!submissionId) {
      return { error: 'submissionId is required' };
    }

    const room = `submission:${submissionId}`;
    client.leave(room);
    
    this.logger.log(`Client ${client.id} unsubscribed from ${room}`);
    
    return { unsubscribed: true, submissionId };
  }

  /**
   * Emit submission status update to all subscribed clients
   */
  emitSubmissionUpdate(submissionId: string, data: any) {
    const room = `submission:${submissionId}`;
    this.server.to(room).emit('update', {
      submissionId,
      timestamp: new Date().toISOString(),
      ...data,
    });
    
    this.logger.log(`Emitted update to ${room}:`, data.status);
  }

  /**
   * Emit test result update (for progressive feedback)
   */
  emitTestResult(submissionId: string, testIndex: number, result: any) {
    const room = `submission:${submissionId}`;
    this.server.to(room).emit('test-result', {
      submissionId,
      testIndex,
      result,
      timestamp: new Date().toISOString(),
    });
  }
}
