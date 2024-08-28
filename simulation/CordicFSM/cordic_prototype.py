"""Goal: Understand the CORDIC algorithm that takes as input x = r * sin(phi) and y = r * cos(phi) and outputs r and phi."""

import matplotlib.pyplot as plt
import numpy as np


def float_to_fixed(x, n_bits=16):
    """Converts a floating point number to a signed fixed point number with n_bits bits.

    The range [-1, 1] gets mapped to the range [-2^(n_bits-1)-1, 2^(n_bits-1)-1].
    Note that the most negative signed integer gets mapped to slightly less than -1, because of the assymmetry inherent to standard signed integers.
    """
    return int(x * (2 ** (n_bits - 1) - 1))


def fixed_to_float(x, n_bits=16):
    """Converts a signed fixed point number with n_bits bits to a floating point number."""
    return x / (2 ** (n_bits - 1) - 1)


def get_gamma(n_iter=16, n_bits=16):
    """Returns the CORDIC rotation angles gamma_i."""

    gamma = [np.arctan(2 ** (-i)) for i in range(n_iter)]

    # convert to fixed point
    for i in range(n_iter):
        gamma[i] = float_to_fixed(gamma[i] / np.pi, n_bits)

    return gamma


def print_verilog_array(array):
    """Prints an array in Verilog format, e.g. {10, 3, 2}"""

    print("{", end="")
    for i, element in enumerate(array):
        print(f"{element}", end="")

        # unless it's the last element, print ", "
        if i != len(array) - 1:
            print(", ", end="")
    print("}")


def get_range(n_bits):
    """Returns the range of a signed fixed point number with n_bits bits."""
    min_val = -(2 ** (n_bits - 1))
    max_val = 2 ** (n_bits - 1) - 1
    return min_val, max_val


def cartesian_to_phi_cordic(x, y, n_iter=16):
    """Converts x = sin(phi) and y = cos(phi) to phi = arctan(y/x) using the CORDIC algorithm.

    phi is in the range [-2^n_bits, 2^nbits - 1], corresponding to [-pi, pi - epsilon].
    r is in the range [0, 2^n_bits - 1], corresponding to [0, 1]."""

    n_bits = n_iter

    # To avoid overflow for internal variables, extend the number of internal bits by 1.
    # This is necessary, as phi may initially overshoot during the calculation to be greater than pi.
    n_bits_extended = n_bits + 1  

    # Initialize the CORDIC rotation table
    gammas = get_gamma(n_iter, n_bits)

    # get pi in fixed point
    pi_fixed = float_to_fixed(np.pi / np.pi, n_bits)  # scale such that pi is the maximum number representable in n_bits

    # assert starting values are in range
    min_val, max_val = get_range(n_bits)
    for var in [x, y, pi_fixed]:
        assert min_val <= var <= max_val

    phi = 0

    # if (x,y) is on the left half-plane, flip it to the right half-plane, and keep track of the total rotation angle
    if x < 0:
        if y > 0:
            phi = pi_fixed
        else:
            phi = -pi_fixed
        x, y = -x, -y

    # iterate the CORDIC algorithm
    for j in range(n_iter):
        # decide whether to rotate clockwise or counterclockwise
        d = 1 if y >= 0 else -1

        # apply the rotation matrix to the vector (x, y)
        x, y = x + (y >> j) * d, y - (x >> j) * d

        # keep track of the total rotation angle
        phi += d * gammas[j]

        # assert all values are still in range
        min_val, max_val = get_range(n_bits_extended)
        for var in [x, y, phi]:
            assert min_val <= var <= max_val

    return phi, x


def main():
    """Plot the CORDIC algorithm's output phi as a function of the true phi."""

    n_iter = 24
    n_bits = 24

    phis_true = np.linspace(-np.pi, np.pi - 1e-6, 100)
    xs = np.cos(phis_true)
    ys = np.sin(phis_true)

    phis = np.zeros(len(phis_true))
    for i in range(len(phis_true)):
        x = float_to_fixed(xs[i], n_bits)
        y = float_to_fixed(ys[i], n_bits)
        phis[i], _ = cartesian_to_phi_cordic(x, y, n_iter)
        phis[i] = fixed_to_float(phis[i], n_bits) * np.pi

    # plot with residuals underneath
    _, axs = plt.subplots(2, 1, sharex=True)
    axs[0].plot(phis_true, phis)
    axs[0].set_ylabel("CORDIC phi")
    axs[1].plot(phis_true, phis - phis_true)
    axs[1].set_ylabel("residual")
    axs[1].set_xlabel("true phi")
    plt.show()


if __name__ == "__main__":
    main()
