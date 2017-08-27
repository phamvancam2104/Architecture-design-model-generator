package org.eclipse.papyrus.ucsusm.generator.ui;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.core.runtime.jobs.IJobChangeEvent;
import org.eclipse.core.runtime.jobs.Job;
import org.eclipse.core.runtime.jobs.JobChangeAdapter;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.ITreeSelection;
import org.eclipse.papyrus.ucsusm.generator.ModelGenerator;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.uml2.uml.Model;

public class ArchitectureModelGenerator extends AbstractHandler {
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		try {
			ISelection selection = HandlerUtil.getCurrentSelection(event);

			if (selection instanceof ITreeSelection) {
				ITreeSelection tree = (ITreeSelection) selection;
				Object obj = tree.getFirstElement();
				if (obj instanceof IProject) {
					scheduleReverse((IProject) obj);
				}
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

		return null;
	}
	
	private void scheduleReverse(final IProject project) {
		if (project != null) {
			Job job = new Job("Generating random architecture design models") { // $NON-NLS-1$

				@Override
				protected IStatus run(final IProgressMonitor monitor) {
					try {
						Display display = new Display();
						final Shell shell = new Shell(display);

						shell.setSize(300, 600);
						GridLayout gridLayout = new GridLayout(1, true);
						shell.setLayout(gridLayout);
						shell.open();

						Label label = new Label(shell, SWT.BORDER);

						label.setText("Enter the number of models and the numbers of structural and architecture model elements");
						label.setLocation(10, 10);
						label.pack();
						
						//Label labelModel = new Label(shell, SWT.NONE);
						//labelModel.setText("The number of models");
						final Text textModel = new Text(shell, SWT.NONE);
						
						//Label labelStructure = new Label(shell, SWT.NONE);
						//labelModel.setText("Structural elements");
						final Text textStructure = new Text(shell, SWT.NONE);
						
						//Label labelBehavior = new Label(shell, SWT.NONE);
						//labelModel.setText("Behaviral elements");
						final Text textBehavior = new Text(shell, SWT.NONE);
						

						Button button = new Button(shell, SWT.PUSH);
						button.setText("OK");
						//button.setSize(50, 50);
						//button.setLocation(10, 75);
						
						button.addSelectionListener(new SelectionAdapter() {
							public void widgetSelected(SelectionEvent e) {
								ModelGenerator.setNumberofElements(Integer.parseInt(textStructure.getText()), Integer.parseInt(textBehavior.getText()));
								int numberOfModels = Integer.parseInt(textModel.getText());
								try {
									for (int i = 0; i < numberOfModels; i++) {
										final ModelGenerator generator = new ModelGenerator();
										Model model = generator.generateAModel(i, project, "generatedmodels");
										//generator.saveAModel(model);
										generator.dispose(model);
									}
								} catch (Exception e1) {
									e1.printStackTrace();
								}
								shell.dispose();
							}
						});

						while (!shell.isDisposed()) {
							if (!display.readAndDispatch())
								display.sleep();
						}
						display.dispose();
					} catch (Exception e) {
						e.printStackTrace();
					}

					return Status.OK_STATUS;
				}

			};

			job.setUser(true);
			
			job.addJobChangeListener(new JobChangeAdapter() {
				@Override
				public void done(IJobChangeEvent event) {
					Display.getDefault().syncExec(new Runnable() {
						@Override
						public void run() {
							try {
								Shell shell = Display.getDefault().getActiveShell();
								if (shell != null) {
									MessageBox messageBox = new MessageBox(shell, SWT.ICON_INFORMATION | SWT.OK);
									messageBox.setMessage("Generated UML-based design models in generatedmodels/ folder of project " + project.getName()); // $NON-NLS-1$
									messageBox.open();
								}
							} catch (Exception e) {
								e.printStackTrace();
							}
							
						}
					});
				}
			});
			
			job.schedule();
		}
	}
}
