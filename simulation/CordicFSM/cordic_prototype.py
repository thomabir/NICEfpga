"""Goal: Understand the CORDIC algorithm that takes as input sin(phi) and cos(phi) and outputs phi."""

import matplotlib.pyplot as plt
import numpy as np


def float_to_fixed(x, n_bits=16):
    """Converts a floating point number to a signed fixed point number with n_bits bits."""
    return int(x * (2 ** (n_bits - 1)))


def fixed_to_float(x, n_bits=16):
    """Converts a signed fixed point number with n_bits bits to a floating point number."""
    return x / (2 ** (n_bits - 1))


def get_gamma(n_iter=16, n_bits=16):
    """Returns the CORDIC rotation angles gamma_i."""

    gamma = [np.arctan(2 ** (-i)) for i in range(n_iter)]

    # convert to fixed point
    for i in range(n_iter):
        gamma[i] = float_to_fixed(gamma[i], n_bits)

    return gamma

def print_verilog_array(array):

    # print in this format: {10, 3, ...}
    print("{", end="")
    for i in range(len(array)):
        print(f"{array[i]}, ", end="")
    print("}")


def cartesian_to_phi_cordic(x, y, n_iter=16):
    """Converts x = sin(phi) and y = cos(phi) to phi = arctan(y/x) using the CORDIC algorithm."""

    n_bits = n_iter
    n_bits_extended = n_bits + 1  # to avoid overflow for internal variables

    # define the maximum and minimum values for the fixed point variables
    max_val = 2 ** (n_bits_extended - 1) - 1
    min_val = -(2 ** (n_bits_extended - 1))

    # Initialize the CORDIC rotation table
    gammas = get_gamma(n_iter, n_bits)

    # convert to fixed point
    x = float_to_fixed(x, n_bits)
    y = float_to_fixed(y, n_bits)

    # iterate the CORDIC algorithm
    phi = 0
    for j in range(n_iter):
        # decide whether to rotate clockwise or counterclockwise
        if y >= 0:
            d = 1
        else:
            d = -1

        # apply the rotation matrix to the vector (x, y)
        x, y = x + (y >> j) * d, y - (x >> j) * d

        # keep track of the total rotation angle
        phi += d * gammas[j]

        # assert all values are still in range
        for var in [x, y, phi]:
            assert min_val <= var <= max_val

    # Convert back to floating point
    phi = fixed_to_float(phi, n_bits)

    return phi


def main():
    """Plot the CORDIC algorithm's output phi as a function of the true phi."""

    n_iter = 24
    n_bits = 24

    phis_true = np.linspace(-np.pi / 2, np.pi / 2, 100)
    xs = np.cos(phis_true)
    ys = np.sin(phis_true)

    # print gamma
    gammas = get_gamma(n_iter, n_bits)
    print_verilog_array(gammas)

    phis = np.zeros(len(phis_true))
    for i in range(len(phis_true)):
        phis[i] = cartesian_to_phi_cordic(xs[i], ys[i], n_iter)

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
