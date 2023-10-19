"""Goal: Understand the CORDIC algorithm that takes as input sin(phi) and cos(phi) and outputs phi."""

import matplotlib.pyplot as plt
import numpy as np


def float_to_fixed(x, n_bits=16):
    """Converts a floating point number to a signed fixed point number with n_bits bits."""
    return int(x * (2 ** (n_bits - 1)))


def fixed_to_float(x, n_bits=16):
    """Converts a signed fixed point number with n_bits bits to a floating point number."""
    return x / (2 ** (n_bits - 1))


def cartesian_to_phi_cordic(x, y, n_iter=16):
    """Converts x = sin(phi) and y = cos(phi) to phi = arctan(y/x) using the CORDIC algorithm."""

    n_bits = n_iter

    # Initialize the CORDIC rotation table
    gamma = [np.arctan(2 ** (-i)) for i in range(n_iter)]

    # convert to fixed point
    x = float_to_fixed(x, n_bits)
    y = float_to_fixed(y, n_bits)

    for i in range(n_iter):
        gamma[i] = float_to_fixed(gamma[i] * 0.5, n_bits)

    # print in this format: {10, 3, ...}
    print("{", end="")
    for i in range(n_iter):
        print(f"{gamma[i]}, ", end="")
    print("}")

    print(gamma)

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
        phi += d * gamma[j]

    # Convert back to floating point
    phi = fixed_to_float(phi, n_bits)

    return phi


def main():
    """Plot the CORDIC algorithm's output phi as a function of the true phi."""

    n_iter = 24

    phis_true = np.linspace(-np.pi / 2, np.pi / 2, 100)
    xs = np.cos(phis_true)
    ys = np.sin(phis_true)

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
