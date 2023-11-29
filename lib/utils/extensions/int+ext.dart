
extension TimeDivisionExtension on int {
  String divideTime() {
    // Convert the minutes to hours and minutes
    int hours = this ~/ 60;
    int minutes = this % 60;

    // Format the result as HH:mm
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}