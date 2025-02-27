# Copyright (c) 2023, NVIDIA CORPORATION.

from libcpp.memory cimport unique_ptr

from cudf._lib.cpp.table.table cimport table
from cudf._lib.cpp.table.table_view cimport table_view


cdef class Table:
    # List[pylibcudf.Column]
    cdef object columns

    cdef table_view view(self) nogil

    @staticmethod
    cdef Table from_libcudf(unique_ptr[table] libcudf_tbl)
