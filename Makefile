## Start PDE1D build configuration
# Search paths for include files, starting with only the platform-independent
# paths.
INC:=-Ipde1dlib -IFDJacobian -Iutil

# Flags for compilation step.
CPPFLAGS:=-g -Wno-deprecated-declarations -DEIGEN_DEFAULT_DENSE_INDEX_TYPE=int64_t

# Flags for link step
LDFLAGS?=

##
# Begin Platform-Specific Configuration
##
# Test platform name
UNAME_S:=$(shell uname -s)

ifeq (${UNAME_S},Darwin) # Default MacOS-Based configuration
# Eigen-related directories
EIGEN_INCDIR?=/usr/local/include/eigen3
INC+=-I${EIGEN_INCDIR}

# Sundials-related directories
SUNDIALS_LDIR?=$(wildcard /usr/local/Cellar/sundials/*/lib/)
SUNDIALS_INCDIR?=$(wildcard /usr/local/Cellar/sundials/*/include/)
INC+=-I${SUNDIALS_INCDIR}

# Suitesparse-related directories
SUITESPARSE_LDIR?=$(wildcard /usr/local/Cellar/suite-sparse/5.*/lib/)
SUITESPARSE_INCDIR?=$(wildcard /usr/local/Cellar/suite-sparse/5.*/include/)
INC+=-I${SUITESPARSE_INCDIR}

OCTAVE_LDIR?=$(wildcard /usr/local/lib/octave/4.*/)
OCTAVE_INCDIR?=$(wildcard /usr/local/include/octave-4.*/octave/)

# Set USE_OCTAVE=true to compile against GNU Octave
ifneq (${USE_OCTAVE},)
INC+=-I${OCTAVE_INCDIR}
endif # USE_OCTAVE Non-empty

CPPFLAGS+=-fms-extensions
endif # End MacOS-related configuration

##
##

ifeq (${UNAME_S},Linux) # Default Linux-based configuration
# Eigen-related directories
EIGEN_INCDIR?=/usr/include/eigen3
INC+=-I${EIGEN_INCDIR}

# Sundials-related directories
SUNDIALS_LDIR?=/usr/lib
SUNDIALS_INCDIR?=/usr/include/sundials
INC+=-I${SUNDIALS_INCDIR}

# Suitesparse-related directories
SUITESPARSE_LDIR?=/usr/lib/x86_64-linux-gnu
SUITESPARSE_INCDIR?=/usr/include/suitesparse
INC+=-I${SUITESPARSE_INCDIR}

OCTAVE_LDIR?=/usr/local/lib/octave
OCTAVE_INCDIR?=$(wildcard /usr/include/octave-4.*/octave/)

# Set USE_OCTAVE=true to compile against GNU Octave
ifneq (${USE_OCTAVE},)
INC+=-I${OCTAVE_INCDIR}
endif # USE_OCTAVE Non-empty
endif # End Linux-related configuration

##
# End Platform-Specific Configuration Variables
##

# Libraries for link step
LDLIBS=-L${SUNDIALS_LDIR} \
			 -lsundials_ida \
			 -lsundials_nvecserial \
			 -lsundials_sunlinsolklu \
			 -L${SUITESPARSE_LDIR} \
			 -lklu


ifeq (${USE_OCTAVE},) # If USE_OCTAVE is Empty
CPPFLAGS+= -O2 -std=gnu++0x
LDFLAGS+= -shared
endif # End USE_OCTAVE Empty

CPPFLAGS+=${INC}
## End PDE1D Build Configuration

##
# Usage target
##
usage:
	@echo "make TARGET [OPTIONS]"
	@echo ""
	@echo " Valid Targets:"
	@echo "    - pde1d.mex: Build main PDE solver Mex-file"
	@echo "    - clean: Remove object files."
	@echo " Options/Variables"
	@echo "    - USE_OCTAVE: Set to true to build against Octave."
	@echo "    - OCTAVE_INCDIR: Path to Octave include files"
	@echo "    - OCTAVE_LDIR: Path to Octave library files"
	@echo "    - SUNDIALS_INCDIR: Path to Sundials include files"
	@echo "    - SUNDIALS_LDIR: Path to Sundials library files"
	@echo "    - SUITESPARSE_INCDIR: Path to Suitesparse include files"
	@echo "    - SUITESPARSE_LDIR: Path to Suitesparse library files"
	@echo "    - EIGEN_INCDIR: Path to Eigen include files"

# Files under pde1dlib we expect to have built
PDELIBFILES:=PDE1dImpl \
						 PDE1dDefn \
						 PDEInitConditions \
						 GausLegendreIntRule \
						 SunVector \
						 PDEMeshMapper \
						 PDEModel \
						 PDEElement \
						 PDEEvents \
						 PDESolution \
						 ShapeFunctionManager \
						 ShapeFunctionHierarchical \
						 ShapeFunction

# All built objects
OBJS:=$(addprefix FDJacobian/,FDJacobian.o FiniteDiffJacobian.o) \
		  $(addprefix pde1dmex/,pde1dmex.o PDE1dMexInt.o MexInterface.o) \
		  $(addprefix util/,util.o) \
		  $(addprefix pde1dlib/,$(addsuffix .o,${PDELIBFILES}))

# Scrape active subdirectories from OBJS
SUBDIRS:=$(subst /,,$(sort $(dir ${OBJS})))

objects: ${OBJS}

# Define build instructions for object files and final mex product
# separately. The instructions differ when building against Octave.
ifneq (${USE_OCTAVE},)
%.o: %.c
	mkoctfile --mex ${CPPFLAGS} -c -o $@ $<

%.o: %.cpp
	mkoctfile --mex ${CPPFLAGS} -c -o $@ $<

pde1d.mex: ${OBJS}
	mkoctfile --mex ${LDFLAGS} -o $@ $^ ${LDLIBS}

else # end USE_OCTAVE Nonempty
%.o: %.c
	$(CXX) ${CPPFLAGS} -c -o $@ $<

%.o: %.cpp
	$(CXX) ${CPPFLAGS} -c -o $@ $<

pde1d.mex: ${OBJS}
	$(CXX) ${LDFLAGS} -o $@ $^ ${LDLIBS}

endif # end USE_OCTAVE Empty
# End build instructions for object files

clean:
	$(RM) $(foreach dir,${SUBDIRS},${dir}/*.o)

clean-all: clean
	$(RM) pde1d.mex
