import java.util.Arrays;
import java.util.Comparator;
import java.util.Random;

public static final class ArrayUtils {
    public static int[] argsort(final float[] a) {
        return argsort(a, true);
    }

    public static int[] argsort(final float[] a, final boolean ascending) {
        Integer[] indexes = new Integer[a.length];
        for (int i = 0; i < indexes.length; i++) {
            indexes[i] = i;
        }
        Arrays.sort(indexes, new Comparator<Integer>() {
            @Override
            public int compare(final Integer i1, final Integer i2) {
                return (ascending ? 1 : -1) * Float.compare(a[i1], a[i2]);
            }
        });
        return asArray(indexes);
    }

    public static <T extends Number> int[] asArray(final T... a) {
        int[] b = new int[a.length];
        for (int i = 0; i < b.length; i++) {
            b[i] = a[i].intValue();
        }
        return b;
    }

    public static double[] castOf(final float[] x) {
        double[] y = new double[x.length];
        for (int i = 0; i < y.length; i++) {
            y[i] = x[i];
        }
        return y;
    }

    public static int[] castOf(final long[] original) {
        return castOf(original, original.length);
    }

    public static int[] castOf(final long[] original, final int newLength) {
        int[] cast = new int[newLength];
        int length = Math.min(cast.length, original.length);
        for (int i = 0; i < length; i++) {
            long o = original[i];
            if (o < Integer.MIN_VALUE || o > Integer.MAX_VALUE) {
                throw new IllegalArgumentException();
            }
            cast[i] = (int) o;
        }
        return cast;
    }

    public static float[][] copyOf(final float[][] x, final int newLength) {
        float[][] y = new float[newLength][];
        for (int i = 0; i < y.length; i++) {
            if (x[i] != null) {
                y[i] = Arrays.copyOf(x[i], x[i].length);
            }
        }
        return y;
    }

    /**
     * Assigns a random value to each element of the specified array of doubles.
     */
    public static void fillRandom(final double[] x, final Random rng) {
        for (int i = 0; i < x.length; i++) {
            x[i] = rng.nextDouble();
        }
    }

    private ArrayUtils() {
    }
}
