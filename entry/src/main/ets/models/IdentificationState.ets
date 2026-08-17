/** Reserved state contract for the real identification service. No AI is connected in this phase. */
export enum IdentificationState {
  IDLE = 'Idle',
  IMAGE_SELECTED = 'ImageSelected',
  IDENTIFYING = 'Identifying',
  SUCCESS = 'Success',
  LOW_CONFIDENCE = 'LowConfidence',
  LIMIT_REACHED = 'LimitReached',
  FAILED = 'Failed'
}
