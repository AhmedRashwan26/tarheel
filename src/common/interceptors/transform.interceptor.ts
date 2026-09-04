import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface StandardResponse<T> {
  success: boolean;
  statusCode: number;
  message?: string;
  data: T;
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, StandardResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<StandardResponse<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();
    const statusCode = response.statusCode;

    return next.handle().pipe(
      map((result) => {
        let message = 'تمت العملية بنجاح';
        let data = result;

        if (
          result &&
          typeof result === 'object' &&
          'message' in result &&
          'data' in result
        ) {
          message = result.message;
          data = result.data;
        }

        return {
          success: true,
          statusCode,
          message,
          data: data !== undefined ? data : null,
        };
      }),
    );
  }
}
