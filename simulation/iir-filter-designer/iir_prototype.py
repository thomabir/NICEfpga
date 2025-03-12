"""An IIR filter implemented in Python"""

import matplotlib.pyplot as plt
import numpy as np


def iir(input, num, denom):
    """Apply an IIR filter to an input signal. Only uses fixed-point arithmetic.

    Args:
        input (list): Input signal.
        num (list): Numerator coefficients.
        denom (list): Denominator coefficients.

    Returns:
        list: Filtered signal.
    """

    P = len(num)
    Q = len(denom)
    n = len(num) - 1  # index of the last element in the input vector

    # Initialize the state

    state = np.zeros(n + 1, dtype=int)

    # Initialize the output signal
    output = np.zeros(len(input), dtype=int)

    for i in range(len(input)):
        # Update the state
        # (this is the 'x' vector in the difference equation)
        state = np.roll(state, 1)
        state[0] = input[i]

        # Calculate the output
        y = 0
        for j in range(P):
            y += num[j] * state[n - j]
        for j in range(1, Q):
            y -= denom[j] * output[i - j]
        y = y / denom[0]

        # Update the output signal
        output[i] = y

    return output


# test IIR with a simple example

num = [1, 0, 0]
denom = [1, 0, 0]

# num = [ 0.00490303,  0.   ,      -0.00980607 , 0.     ,     0.00490303]
# denom = [ 1.     ,    -3.7740912 ,  5.36207789, -3.39990059,  0.81199778]

input = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
output = iir(input, num, denom)

print(output)
