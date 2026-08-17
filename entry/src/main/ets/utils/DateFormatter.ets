export class DateFormatter {
  static short(date: Date): string {
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${date.getFullYear()}.${month}.${day}`;
  }

  static monthAndDay(date: Date): string {
    return `${date.getMonth() + 1} 月 ${date.getDate()} 日`;
  }

  static time(date: Date): string {
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${hour}:${minute}`;
  }
}
