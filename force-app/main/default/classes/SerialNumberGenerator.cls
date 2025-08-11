public class SerialNumberGenerator {

    public static String generateDateBasedSerialNumber() {
        Long millis = System.currentTimeMillis();
        String millisStr = String.valueOf(millis);

        // Pad left with zeros to ensure length is at least 8
        String serial = padLeft(millisStr, 8, '0');

        // Take last 8 characters (in case millis string is longer)
        if (serial.length() > 8) {
            serial = serial.substring(serial.length() - 8);
        }
        return serial;
    }

    private static String padLeft(String input, Integer totalLength, String padChar) {
        if (input == null) input = '';
        while (input.length() < totalLength) {
            input = padChar + input;
        }
        return input;
    }
}