/*============================================================================*/
/*                                                                            */
/*                                                                            */
/*                             boOX 2-041_planck                              */
/*                                                                            */
/*                  (C) Copyright 2018 - 2020 Pavel Surynek                   */
/*                                                                            */
/*                http://www.surynek.net | <pavel@surynek.net>                */
/*       http://users.fit.cvut.cz/surynek | <pavel.surynek@fit.cvut.cz>       */
/*                                                                            */
/*============================================================================*/
/* rota_solver_main.h / 2-041_planck                                          */
/*----------------------------------------------------------------------------*/
//
// Token Rotation Problem Solver - main program.
//
// CBS-based and SMT-based solvers for token rotation problem (swaps excluding).
//
/*----------------------------------------------------------------------------*/


#ifndef __ROTA_SOLVER_MAIN_H__
#define __ROTA_SOLVER_MAIN_H__

#include "config.h"
#include "compile.h"
#include "defs.h"
#include "version.h"

using namespace std;


/*----------------------------------------------------------------------------*/

namespace boOX
{


/*----------------------------------------------------------------------------*/

    struct sCommandParameters
    {	
	enum Algorithm
	{
	    ALGORITHM_CBS,
	    ALGORITHM_CBS_PLUS,
	    ALGORITHM_CBS_PLUS_PLUS,
	    ALGORITHM_CBS_PLUS_PLUS_PLUS,	    
	    ALGORITHM_SMTCBS,
	    ALGORITHM_SMTCBS_PLUS,
	    ALGORITHM_SMTCBS_PLUS_PLUS	    
	};

	sCommandParameters();
        /*--------------------------------*/

	sInt_32 m_cost_limit;
	Algorithm m_algorithm;
	bool m_capacitated;

	sString m_input_filename;		
	sString m_output_filename;

	sDouble m_subopt_ratio;		
	sDouble m_timeout;
    };


/*----------------------------------------------------------------------------*/

    void print_IntroductoryMessage(void);
    void print_ConcludingMessage(void);
    void print_Help(void);
    
    sResult parse_CommandLineParameter(const sString &parameter, sCommandParameters &parameters);
    sResult solve_TokenRotationInstance(const sCommandParameters &parameters);


/*----------------------------------------------------------------------------*/

} // namespace boOX


#endif /* __ROTA_SOLVER_MAIN_H__ */
