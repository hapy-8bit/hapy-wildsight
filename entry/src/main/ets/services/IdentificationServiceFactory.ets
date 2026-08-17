import { IdentificationService } from './IdentificationService';
import { IdentificationConfiguration, IdentificationMode } from './IdentificationMode';
import { MockIdentificationService } from './MockIdentificationService';
import { RemoteIdentificationService } from './RemoteIdentificationService';

export class IdentificationServiceFactory {
  static create(): IdentificationService {
    if (IdentificationConfiguration.mode === IdentificationMode.REMOTE) {
      return new RemoteIdentificationService(IdentificationConfiguration.backendEndpoint);
    }
    return new MockIdentificationService();
  }
}
