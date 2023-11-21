#ifndef MY_MATRIX_H
#define MY_MATRIX_H
#include "xil_types.h"
#include "Defines.h"

class Matrix {
private:
    int real_cols;
    int real_rows;
    int real_size;
    DATA_TYPE * base_addr;

public:
    int rows;
    int cols;
    // constructor
    Matrix(int rows, int cols);

    // destructor
    ~Matrix();

    int get_real_cols() const;
    int get_real_rows() const;
    int get_real_size() const;
    DATA_TYPE* get_base_addr() const;
    void set_value(int row, int col, DATA_TYPE value);
    DATA_TYPE get_value(int row, int col);
    void mat_print();

};
void Matrix_mul_soft(Matrix &A, Matrix &B, Matrix &C, int R_shift); //A*B=C
void Matrix_mul_hard(Matrix &A, Matrix &B, Matrix &C, int R_shift); //A*B=C
bool  Matrix_compare(const Matrix &A, const Matrix &B);
#endif
